import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/storage/secure_token_storage.dart';

const trackingCommandStart = 'tracking:start';
const trackingCommandStop = 'tracking:stop';
const trackingCommandSetMode = 'tracking:set_mode';
const trackingCommandUpdateAuth = 'tracking:update_auth';
const trackingCommandAppendPoint = 'tracking:append_point';
const trackingCommandFlushNow = 'tracking:flush_now';
const trackingEventBufferCount = 'tracking:buffer_count';
const trackingEventFlushSuccess = 'tracking:flush_success';
const trackingEventError = 'tracking:error';
const trackingEventAuthExpired = 'tracking:auth_expired';

const _trackingPointsBoxName = 'tracking_telemetry_points_v1';

const _maxFlushBackoffSeconds = 60;

/// TTL dos pontos de telemetria no buffer local. Pontos mais antigos são
/// removidos na abertura da caixa para evitar vazamento de dados antigos
/// e corrupção de rotas anteriores.
const _telemetryPointTtl = Duration(hours: 24);

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
  static int _authFailureStreak = 0;
  static bool _flushHalted = false;
  static final SecureTokenStorage _tokenStorage = SecureTokenStorage();
  static void Function(String event, Map<String, dynamic> data)? _eventSink;

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
      _authFailureStreak = 0;
      _flushHalted = false;
      await _ensureTelemetryHttpClient();

      // Descarta pontos pré-existentes ao iniciar uma nova rota. Evita que
      // coordenadas da rota anterior sejam enviadas com os IDs da rota atual.
      final box = await _ensurePointsBox();
      await box.clear();
      _emitBufferCount();

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
        _authFailureStreak = 0;
        if (_routeActive && !_flushHalted && _flushTimer != null) {
          _scheduleNextFlush();
        }
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

  static int get _currentFlushDelaySeconds {
    final base = _flushIntervalSeconds;
    if (_authFailureStreak <= 0) return base;
    var delay = base;
    for (var i = 1; i < _authFailureStreak; i++) {
      delay *= 2;
      if (delay >= _maxFlushBackoffSeconds) return _maxFlushBackoffSeconds;
    }
    return delay > _maxFlushBackoffSeconds ? _maxFlushBackoffSeconds : delay;
  }

  static void _startFlushTimer() {
    if (_flushTimer != null) return;
    _flushHalted = false;
    _scheduleNextFlush();
  }

  static void _scheduleNextFlush() {
    _flushTimer?.cancel();
    if (_flushHalted || !_routeActive) {
      _flushTimer = null;
      return;
    }
    _flushTimer = Timer(Duration(seconds: _currentFlushDelaySeconds), () {
      unawaited(_runScheduledFlush());
    });
  }

  static Future<void> _runScheduledFlush() async {
    if (!_routeActive || _flushHalted) {
      _stopFlushTimer();
      return;
    }
    await _flushTelemetryBatch();
    if (!_routeActive || _flushHalted) {
      _stopFlushTimer();
      return;
    }
    _scheduleNextFlush();
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
        _authFailureStreak = 0;
        await box.deleteAll(keys);
        _emitBufferCount();
        _emit(trackingEventFlushSuccess, <String, dynamic>{
          'sent_count': points.length,
          'remaining_count': box.length,
        });
      } else if (status == 401) {
        _handleUnauthorizedFlush();
      } else if (status == 404) {
        await _handleRouteNotFound(box);
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (status == 401) {
        _handleUnauthorizedFlush();
      } else if (status == 404) {
        await _handleRouteNotFound(box);
      } else {
        _emitError('Falha ao enviar lote em background: $e');
      }
    } catch (e) {
      _emitError('Falha ao enviar lote em background: $e');
    } finally {
      _isFlushing = false;
    }
  }

  static void _handleUnauthorizedFlush() {
    _authFailureStreak++;
    _emit(trackingEventAuthExpired, <String, dynamic>{
      'attempts': _authFailureStreak,
      'next_retry_seconds': _currentFlushDelaySeconds,
    });
  }

  static Future<void> _handleRouteNotFound(Box<dynamic> box) async {
    _authFailureStreak = 0;
    _flushHalted = true;
    _stopFlushTimer();
    try {
      await box.clear();
    } catch (_) {}
    _emitBufferCount();
    _emitError(
      'Rota ativa nao encontrada no servidor: envio de telemetria encerrado.',
    );
  }

  static Future<Box<dynamic>> _ensurePointsBox() async {
    if (_pointsBox?.isOpen == true) return _pointsBox!;

    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    _pointsBox = await Hive.openBox<dynamic>(_trackingPointsBoxName);
    await _evictStalePoints(_pointsBox!);
    return _pointsBox!;
  }

  /// Remove pontos com mais de [_telemetryPointTtl] ou sem timestamp válido.
  /// Usa o campo `timestamp` do ponto (ISO 8601 UTC) para determinar a idade.
  static Future<void> _evictStalePoints(Box<dynamic> box) async {
    final cutoff = DateTime.now().toUtc().subtract(_telemetryPointTtl);
    final keysToDelete = <dynamic>[];

    for (final entry in box.toMap().entries) {
      if (entry.value is! Map) {
        keysToDelete.add(entry.key);
        continue;
      }
      final point = Map<String, dynamic>.from(entry.value as Map);
      final ts = point['timestamp']?.toString();
      if (ts == null || ts.isEmpty) {
        keysToDelete.add(entry.key);
        continue;
      }
      final parsed = DateTime.tryParse(ts);
      if (parsed == null || parsed.isBefore(cutoff)) {
        keysToDelete.add(entry.key);
      }
    }

    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
      _emitBufferCount();
    }
  }

  /// Limpa a caixa de telemetria fora do ciclo de vida da rota. Usado no
  /// sign-out para garantir que pontos não sejam deixados para a próxima conta.
  /// Atenção: se o isolate de background ainda mantiver a caixa aberta, a
  /// operação pode falhar silenciosamente; nesse caso os pontos serão limpos
  /// quando o serviço parar.
  static Future<void> clearTelemetryBox() async {
    Box<dynamic>? box;
    try {
      // Não re-inicializa o Hive aqui: no isolate principal ele já foi
      // configurado por Hive.initFlutter() (main.dart); em testes o setup
      // inicializa um diretório temporário. Se a caixa estiver aberta em outro
      // isolate, a abertura falhará e ignoramos silenciosamente (best effort).
      box = await Hive.openBox<dynamic>(_trackingPointsBoxName);
      await box.clear();
    } catch (_) {
      // Best effort: a caixa pode estar sob controle do isolate de background.
    } finally {
      try {
        await box?.close();
      } catch (_) {}
      // NÃO fecha Hive.close() aqui — outras caixas da sessão podem estar
      // abertas no isolate principal.
    }
  }

  static Future<String?> _resolveAuthHeader() async {
    try {
      final token = await _tokenStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        return 'Bearer $token';
      }
    } catch (_) {}

    final cached = _authHeader;
    if (cached != null && cached.isNotEmpty) return cached;
    return null;
  }

  static Future<void> _ensureTelemetryHttpClient() async {
    final baseUrl = _apiBaseUrl;
    if (_dio == null) {
      if (baseUrl == null || baseUrl.isEmpty) return;
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          headers: const <String, dynamic>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );
    }

    if (baseUrl != null && baseUrl.isNotEmpty) {
      _dio!.options.baseUrl = baseUrl;
    }

    final header = await _resolveAuthHeader();
    if (header != null && header.isNotEmpty) {
      _dio!.options.headers['Authorization'] = header;
    } else {
      _dio!.options.headers.remove('Authorization');
    }
  }

  static void _emit(String event, Map<String, dynamic> data) {
    final sink = _eventSink;
    if (sink != null) {
      sink(event, data);
      return;
    }
    _service?.invoke(event, data);
  }

  static void _emitBufferCount() {
    _emit(trackingEventBufferCount, <String, dynamic>{
      'count': _pointsBox?.length ?? 0,
    });
  }

  static void _emitError(String message) {
    _emit(trackingEventError, <String, dynamic>{'message': message});
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

/// Ponto de entrada público para limpar o buffer de telemetria fora do
/// isolate de background (ex: durante sign-out).
Future<void> clearDriverTrackingTelemetryBox() async {
  await _BackgroundTrackingRuntime.clearTelemetryBox();
}

@visibleForTesting
class DriverTrackingRuntimeTestHarness {
  const DriverTrackingRuntimeTestHarness._();

  static Future<Box<dynamic>> attachBox() async {
    final box = await Hive.openBox<dynamic>(_trackingPointsBoxName);
    _BackgroundTrackingRuntime._pointsBox = box;
    return box;
  }

  static void startRoute({
    required Dio dio,
    required String apiBaseUrl,
    required String routeManifestId,
    required int vanId,
    int flushIntervalSeconds = 2,
    String? authHeader,
  }) {
    _BackgroundTrackingRuntime._dio = dio;
    _BackgroundTrackingRuntime._apiBaseUrl = apiBaseUrl;
    _BackgroundTrackingRuntime._routeManifestId = routeManifestId;
    _BackgroundTrackingRuntime._vanId = vanId;
    _BackgroundTrackingRuntime._flushIntervalSeconds = flushIntervalSeconds;
    _BackgroundTrackingRuntime._authHeader = authHeader;
    _BackgroundTrackingRuntime._routeActive = true;
    _BackgroundTrackingRuntime._authFailureStreak = 0;
    _BackgroundTrackingRuntime._flushHalted = false;
  }

  static set eventSink(
    void Function(String event, Map<String, dynamic> data)? sink,
  ) {
    _BackgroundTrackingRuntime._eventSink = sink;
  }

  static Future<void> flushNow() =>
      _BackgroundTrackingRuntime._flushTelemetryBatch();

  static void startFlushTimer() =>
      _BackgroundTrackingRuntime._startFlushTimer();

  static bool get flushTimerActive =>
      _BackgroundTrackingRuntime._flushTimer != null;

  static bool get flushHalted => _BackgroundTrackingRuntime._flushHalted;

  static int get nextFlushDelaySeconds =>
      _BackgroundTrackingRuntime._currentFlushDelaySeconds;

  static int get authFailureStreak =>
      _BackgroundTrackingRuntime._authFailureStreak;

  static Future<void> reset() async {
    _BackgroundTrackingRuntime._stopFlushTimer();
    _BackgroundTrackingRuntime._eventSink = null;
    _BackgroundTrackingRuntime._dio = null;
    _BackgroundTrackingRuntime._apiBaseUrl = null;
    _BackgroundTrackingRuntime._routeManifestId = null;
    _BackgroundTrackingRuntime._vanId = null;
    _BackgroundTrackingRuntime._authHeader = null;
    _BackgroundTrackingRuntime._routeActive = false;
    _BackgroundTrackingRuntime._authFailureStreak = 0;
    _BackgroundTrackingRuntime._flushHalted = false;
    _BackgroundTrackingRuntime._isFlushing = false;
    _BackgroundTrackingRuntime._pointsBox = null;
  }
}
