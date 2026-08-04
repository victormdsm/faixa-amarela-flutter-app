import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

const trackingCommandStart = 'tracking:start';
const trackingCommandStop = 'tracking:stop';
const trackingCommandSetMode = 'tracking:set_mode';
const trackingCommandUpdateAuth = 'tracking:update_auth';
const trackingCommandAppendPoint = 'tracking:append_point';
const trackingCommandFlushNow = 'tracking:flush_now';
const trackingEventBufferCount = 'tracking:buffer_count';
const trackingEventFlushSuccess = 'tracking:flush_success';
const trackingEventError = 'tracking:error';

const _trackingPointsBoxName = 'tracking_telemetry_points_v1';

enum TrackingRunMode { foreground, background }

class TrackingLocationSettingsFactory {
  static LocationSettings foreground() =>
      _settings(allowBackgroundLocationUpdates: false);

  static LocationSettings background() =>
      _settings(allowBackgroundLocationUpdates: true);

  // Alta frequência de amostragem (distanceFilter 2m / interval 1s) para o
  // acompanhamento do pai ficar quase em tempo real. Impacto de bateria:
  // GPS contínuo em accuracy best consome mais — mitigado pelo fato de o
  // stream só rodar durante a rota ativa; monitorar dreno em campo e, se
  // necessário, voltar distanceFilter para 5-10m no modo background.
  static LocationSettings _settings({
    required bool allowBackgroundLocationUpdates,
  }) {
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 2,
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 2,
          intervalDuration: const Duration(seconds: 1),
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 2,
          allowBackgroundLocationUpdates: allowBackgroundLocationUpdates,
          showBackgroundLocationIndicator: allowBackgroundLocationUpdates,
          activityType: ActivityType.automotiveNavigation,
        );
      default:
        return const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 2,
        );
    }
  }
}

class TrackingPointSerializer {
  static Map<String, dynamic> fromPosition(Position position) {
    final speedKmh = position.speed.isFinite
        ? (position.speed * 3.6).round().clamp(0, 300)
        : 0;
    final heading = position.heading.isFinite
        ? position.heading.round().clamp(0, 360)
        : 0;

    return <String, dynamic>{
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'lat': position.latitude,
      'lng': position.longitude,
      'speed': speedKmh,
      'heading': heading,
    };
  }
}

class _BackgroundTrackingRuntime {
  static ServiceInstance? _service;
  static StreamSubscription<Position>? _positionSubscription;
  static Timer? _flushTimer;
  static Dio? _dio;
  static Box<dynamic>? _pointsBox;
  static TrackingRunMode _mode = TrackingRunMode.foreground;
  static bool _routeActive = false;
  static String? _authHeader;
  static String? _apiBaseUrl;
  static String? _routeManifestId;
  static int? _vanId;
  // Flush 2s: pontos chegam ao backend (e ao socket do pai) quase em tempo
  // real. Bateria/rede: mais POSTs por rota, porém payloads pequenos (GPS a
  // 1s gera no máx. ~2 pontos por lote); aceito conforme requisito do pai
  // ao vivo. Se o dreno/rede pesar, subir para 5s via flush_interval_seconds.
  static int _flushIntervalSeconds = 2;
  static int _pointKeySequence = 0;
  static bool _commandHandlersRegistered = false;
  static bool _isFlushing = false;

  static Future<void> start(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    _service = service;
    await _ensurePointsBox();
    await _configureAndroidForeground(service);

    if (!_commandHandlersRegistered) {
      _commandHandlersRegistered = true;
      _registerCommandHandlers(service);
    }

    _emitBufferCount();
  }

  static Future<bool> handleIosBackgroundFetch(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    _service = service;
    await _ensurePointsBox();
    await _flushTelemetryBatch();
    return true;
  }

  static void _registerCommandHandlers(ServiceInstance service) {
    service.on(trackingCommandStart).listen((payload) async {
      final args = payload ?? const <String, dynamic>{};
      _routeActive = (args['active'] ?? true) == true;
      _authHeader = args['auth_header']?.toString();
      _apiBaseUrl = args['api_base_url']?.toString();
      _routeManifestId = args['route_manifest_id']?.toString();
      _vanId = (args['van_id'] as num?)?.toInt();
      _flushIntervalSeconds =
          ((args['flush_interval_seconds'] as num?)?.toInt() ?? 2).clamp(
            2,
            120,
          );
      await _ensureTelemetryHttpClient();

      final modeValue = (args['mode'] ?? 'foreground').toString();
      _mode = modeValue == 'background'
          ? TrackingRunMode.background
          : TrackingRunMode.foreground;
      await _reconcileLoops();
    });

    service.on(trackingCommandAppendPoint).listen((payload) async {
      if (!_routeActive || payload == null) return;
      await _appendPointToBuffer(Map<String, dynamic>.from(payload));
    });

    service.on(trackingCommandFlushNow).listen((_) async {
      await _flushTelemetryBatch();
    });

    service.on(trackingCommandUpdateAuth).listen((payload) async {
      final auth = payload?['auth_header']?.toString();
      if (auth != null && auth.isNotEmpty) {
        _authHeader = auth;
        await _ensureTelemetryHttpClient();
      }
    });

    service.on(trackingCommandSetMode).listen((payload) async {
      final mode = (payload?['mode'] ?? 'foreground').toString();
      _mode = mode == 'background'
          ? TrackingRunMode.background
          : TrackingRunMode.foreground;
      await _reconcileLoops();
    });

    service.on(trackingCommandStop).listen((_) async {
      await _flushTelemetryBatch();
      _routeActive = false;
      _routeManifestId = null;
      _vanId = null;
      await _reconcileLoops();
      await _cleanupPointsStorage(clearBufferedPoints: true);
      await _service?.stopSelf();
    });
  }

  static Future<void> _configureAndroidForeground(
    ServiceInstance service,
  ) async {
    if (service is AndroidServiceInstance) {
      await service.setAsForegroundService();
      await service.setForegroundNotificationInfo(
        title: 'Faixa Amarela',
        content: 'Rota em andamento',
      );
    }
  }

  static Future<void> _reconcileLoops() async {
    if (_routeActive) {
      _startFlushTimer();
      if (_mode == TrackingRunMode.background) {
        await _startBackgroundGpsStream();
      } else {
        await _stopBackgroundGpsStream();
      }
      return;
    }

    await _stopBackgroundGpsStream();
    _stopFlushTimer();
  }

  static Future<void> _startBackgroundGpsStream() async {
    if (_positionSubscription != null) return;

    try {
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: TrackingLocationSettingsFactory.background(),
          ).listen((position) async {
            await _appendPointToBuffer(
              TrackingPointSerializer.fromPosition(position),
            );
          });
    } catch (e) {
      _emitError('Falha ao iniciar GPS em background: $e');
    }
  }

  static Future<void> _stopBackgroundGpsStream() async {
    final sub = _positionSubscription;
    _positionSubscription = null;
    await sub?.cancel();
  }

  static void _startFlushTimer() {
    if (_flushTimer != null) return;
    _flushTimer = Timer.periodic(Duration(seconds: _flushIntervalSeconds), (_) {
      if (!_routeActive) {
        _stopFlushTimer();
        return;
      }
      unawaited(_flushTelemetryBatch());
    });
  }

  static void _stopFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  static Future<void> _appendPointToBuffer(Map<String, dynamic> point) async {
    final box = await _ensurePointsBox();
    final key =
        '${DateTime.now().microsecondsSinceEpoch}-${_pointKeySequence++}';
    await box.put(key, point);
    _emitBufferCount();
  }

  static Future<void> _flushTelemetryBatch() async {
    if (_isFlushing) return;
    if (!_routeActive) return;
    if (_routeManifestId == null || _vanId == null) return;

    final box = await _ensurePointsBox();
    if (box.isEmpty) return;

    await _ensureTelemetryHttpClient();
    final dio = _dio;
    if (dio == null) return;

    final entries = box.toMap().entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));

    final points = <Map<String, dynamic>>[];
    final keys = <dynamic>[];
    for (final entry in entries) {
      if (entry.value is Map) {
        points.add(Map<String, dynamic>.from(entry.value as Map));
        keys.add(entry.key);
      }
      if (points.length >= 500) break;
    }

    if (points.isEmpty) return;

    _isFlushing = true;
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/driver/telemetry/batch',
        data: <String, dynamic>{
          'routeManifestId': _routeManifestId,
          'vanId': _vanId,
          'points': points,
        },
      );

      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        await box.deleteAll(keys);
        _emitBufferCount();
        _service?.invoke(trackingEventFlushSuccess, <String, dynamic>{
          'sent_count': points.length,
          'remaining_count': box.length,
        });
      }
    } catch (e) {
      _emitError('Falha ao enviar lote em background: $e');
    } finally {
      _isFlushing = false;
    }
  }

  static Future<Box<dynamic>> _ensurePointsBox() async {
    if (_pointsBox?.isOpen == true) return _pointsBox!;

    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    _pointsBox = await Hive.openBox<dynamic>(_trackingPointsBoxName);
    return _pointsBox!;
  }

  static Future<void> _ensureTelemetryHttpClient() async {
    if (_apiBaseUrl == null || _apiBaseUrl!.isEmpty) return;
    _dio ??= Dio(
      BaseOptions(
        baseUrl: _apiBaseUrl!,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: const <String, dynamic>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio!.options.baseUrl = _apiBaseUrl!;
    if (_authHeader != null && _authHeader!.isNotEmpty) {
      _dio!.options.headers['Authorization'] = _authHeader!;
    } else {
      _dio!.options.headers.remove('Authorization');
    }
  }

  static void _emitBufferCount() {
    _service?.invoke(trackingEventBufferCount, <String, dynamic>{
      'count': _pointsBox?.length ?? 0,
    });
  }

  static void _emitError(String message) {
    _service?.invoke(trackingEventError, <String, dynamic>{'message': message});
  }

  static Future<void> _cleanupPointsStorage({
    bool clearBufferedPoints = false,
  }) async {
    await _stopBackgroundGpsStream();
    _stopFlushTimer();
    if (clearBufferedPoints) {
      try {
        await _pointsBox?.clear();
        _emitBufferCount();
      } catch (_) {}
    }
    try {
      await _pointsBox?.close();
    } catch (_) {}
    _pointsBox = null;
    try {
      await Hive.close();
    } catch (_) {}
  }
}

@pragma('vm:entry-point')
void trackingBackgroundOnStart(ServiceInstance service) {
  unawaited(_BackgroundTrackingRuntime.start(service));
}

@pragma('vm:entry-point')
Future<bool> trackingIosBackground(ServiceInstance service) async {
  return _BackgroundTrackingRuntime.handleIosBackgroundFetch(service);
}
