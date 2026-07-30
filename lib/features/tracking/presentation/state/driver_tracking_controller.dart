import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/backend_config.dart';
import '../../../../core/network/network_providers.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../data/driver_tracking_runtime.dart';
import 'driver_tracking_state.dart';

class DriverTrackingController extends Notifier<DriverTrackingState>
    with WidgetsBindingObserver {
  @override
  DriverTrackingState build() {
    _dio = ref.watch(dioProvider);
    ref.listen(appSessionControllerProvider, (previous, next) {
      syncSession(next.session);
    });
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _foregroundPositionSubscription?.cancel();
      _bufferCountSubscription?.cancel();
      _flushSuccessSubscription?.cancel();
      _errorSubscription?.cancel();
    });
    return const DriverTrackingState();
  }

  late Dio _dio;
  final FlutterBackgroundService _backgroundService =
      FlutterBackgroundService();
  final MethodChannel _permissionsChannel = const MethodChannel(
    'com.faixaamarela.app/tracking_permissions',
  );

  StreamSubscription<Position>? _foregroundPositionSubscription;
  StreamSubscription<Map<String, dynamic>?>? _bufferCountSubscription;
  StreamSubscription<Map<String, dynamic>?>? _flushSuccessSubscription;
  StreamSubscription<Map<String, dynamic>?>? _errorSubscription;

  String? _authHeader;
  bool _initialized = false;
  bool _serviceConfigured = false;
  bool _isGeofenceRequestInFlight = false;
  DateTime? _lastGeofenceCheckAt;
  bool _isRouteRecalcInFlight = false;
  DateTime? _lastRouteRecalcAt;
  int _deviationDistanceThresholdMeters = 100;
  int _deviationSustainSeconds = 10;
  int _deviationDebounceSeconds = 30;
  DateTime? _offRouteSince;
  DateTime? _lastDeviationRecalcAt;

  bool get _supportsBackgroundService =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);

    if (_supportsBackgroundService) {
      await _configureBackgroundService();
      if (_serviceConfigured) {
        _listenBackgroundServiceEvents();
      }
    }

    state = state.copyWith(initialized: true, clearError: true);
  }

  void syncSession(AuthSession? session) {
    _authHeader = session?.authorizationHeader;

    if (_supportsBackgroundService &&
        _authHeader != null &&
        _authHeader!.isNotEmpty) {
      try {
        _backgroundService.invoke(trackingCommandUpdateAuth, <String, dynamic>{
          'auth_header': _authHeader,
        });
      } catch (_) {}
    }

    if (session == null && state.routeActive) {
      unawaited(stopRouteTracking(silent: true));
    }
  }

  Future<bool> startRouteTracking({
    required AuthSession session,
    required int routeId,
    required String routeManifestId,
    required int vanId,
    int geofenceRadiusMeters = 50,
    int deviationDistanceMeters = 100,
    int deviationSustainSeconds = 10,
    int deviationDebounceSeconds = 30,
  }) async {
    await initialize();
    _authHeader = session.authorizationHeader;

    final granted = await _ensureTrackingPermissions();
    if (!granted) {
      state = state.copyWith(
        permissionsGranted: false,
        error:
            'Permita o acesso a localizacao para iniciar o rastreamento da rota.',
      );
      return false;
    }

    final permissionWarning = state.warning;
    state = state.copyWith(
      routeActive: true,
      routeId: routeId,
      routeManifestId: routeManifestId,
      vanId: vanId,
      geofenceRadiusMeters: geofenceRadiusMeters,
      permissionsGranted: true,
      backgroundMode: false,
      clearError: true,
      clearWarning: permissionWarning == null,
      warning: permissionWarning,
      clearGeofence: true,
      clearRoutePreview: true,
      offRoute: false,
      routeRecalculating: false,
    );
    _lastRouteRecalcAt = null;
    _isRouteRecalcInFlight = false;
    _offRouteSince = null;
    _lastDeviationRecalcAt = null;
    _deviationDistanceThresholdMeters = math.max(10, deviationDistanceMeters);
    _deviationSustainSeconds = math.max(1, deviationSustainSeconds);
    _deviationDebounceSeconds = math.max(1, deviationDebounceSeconds);

    if (_supportsBackgroundService) {
      try {
        if (!_serviceConfigured) {
          await _configureBackgroundService();
        }

        final running = await _backgroundService.isRunning();
        if (!running) {
          await _backgroundService.startService();
          await Future<void>.delayed(const Duration(milliseconds: 600));
        }

        try {
          _backgroundService.invoke(trackingCommandStart, <String, dynamic>{
            'active': true,
            'mode': 'foreground',
            'auth_header': _authHeader,
            'api_base_url': BackendConfig.apiBaseUrl,
            'route_id': routeId,
            'route_manifest_id': routeManifestId,
            'van_id': vanId,
            'flush_interval_seconds': 15,
          });
        } catch (_) {}
      } catch (e) {
        state = state.copyWith(warning: 'Servico background indisponivel: $e');
      }
    }

    await _captureInitialPositionAndPrimeRoute();
    await _switchToForegroundMode();
    return true;
  }

  Future<void> stopRouteTracking({bool silent = false}) async {
    await _stopForegroundStream();

    if (_supportsBackgroundService) {
      try {
        _backgroundService.invoke(trackingCommandStop);
      } catch (_) {}
    }

    _lastRouteRecalcAt = null;
    _isRouteRecalcInFlight = false;
    _offRouteSince = null;
    _lastDeviationRecalcAt = null;
    _lastGeofenceCheckAt = null;
    _isGeofenceRequestInFlight = false;

    state = state.copyWith(
      routeActive: false,
      foregroundStreaming: false,
      backgroundMode: false,
      socketConnected: false,
      pendingBufferCount: 0,
      clearRoute: true,
      clearGeofence: true,
      clearRoutePreview: true,
      clearError: silent,
      clearWarning: false,
      offRoute: false,
      routeRecalculating: false,
    );
  }

  void primeRoutePreview({
    List<Map<String, dynamic>>? remainingStops,
    Map<String, dynamic>? geometry,
    double? distanceMeters,
    int? durationSeconds,
  }) {
    final parsedStops = _parseStops(
      remainingStops ?? const <Map<String, dynamic>>[],
    );

    final polyline = _extractPolylinePoints(geometry);
    final mapUrl = (state.lastLatitude != null && state.lastLongitude != null)
        ? _buildExternalDirectionsUrl(
            originLat: state.lastLatitude!,
            originLng: state.lastLongitude!,
            stops: parsedStops
                .map((s) => (name: s.name, lat: s.lat, lng: s.lng))
                .toList(growable: false),
          )
        : state.routePreviewMapUrl;

    state = state.copyWith(
      routeDistanceMeters: distanceMeters ?? state.routeDistanceMeters,
      routeEtaSeconds: durationSeconds ?? state.routeEtaSeconds,
      routePreviewMapUrl: mapUrl ?? state.routePreviewMapUrl,
      routePreviewUpdatedAt: DateTime.now(),
      routeNextStopName: parsedStops.isNotEmpty
          ? parsedStops.first.name
          : state.routeNextStopName,
      routePolyline: polyline.isNotEmpty ? polyline : state.routePolyline,
      routeRemainingStops: parsedStops.isNotEmpty
          ? parsedStops
          : state.routeRemainingStops,
      routePlannedStops: parsedStops.isNotEmpty
          ? _mergePlannedStops(
              previous: state.routePlannedStops,
              incomingRemaining: parsedStops,
            )
          : state.routePlannedStops,
    );
  }

  void markClientBoardedLocal(int childId) {
    _applyClientStopStatusLocal(
      childId: childId,
      targetTypes: _pickupTypes,
      nextStatus: 'picked_up',
    );
  }

  void markClientDisembarkedLocal(int childId) {
    _applyClientStopStatusLocal(
      childId: childId,
      targetTypes: _dropoffTypes,
      nextStatus: 'delivered',
    );
  }

  /// Remove all stops for a given child from local state.
  void removeClientLocal(int childId) {
    final planned = state.routePlannedStops
        .where((s) => (s.childId ?? 0) != childId)
        .toList(growable: false);

    final remaining = planned
        .where((s) {
          final status = s.status.toLowerCase();
          return status != 'picked_up' &&
              status != 'delivered' &&
              status != 'done';
        })
        .toList(growable: false);

    state = state.copyWith(
      routePlannedStops: planned,
      routeRemainingStops: remaining,
      routeNextStopName: remaining.isNotEmpty ? remaining.first.name : null,
    );
  }

  Future<void> refreshRoutePreviewNow() async {
    final lat = state.lastLatitude;
    final lng = state.lastLongitude;
    if (lat == null || lng == null) return;
    final fakePosition = Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: (state.lastHeading ?? 0).toDouble(),
      headingAccuracy: 0,
      speed: ((state.lastSpeedKmh ?? 0) / 3.6),
      speedAccuracy: 0,
    );
    _lastRouteRecalcAt = null;
    await _performRoutePreviewRefresh(fakePosition);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!this.state.routeActive) return;

    if (state == AppLifecycleState.resumed) {
      unawaited(_switchToForegroundMode());
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(_switchToBackgroundMode());
    }
  }

  Future<void> _configureBackgroundService() async {
    if (!_supportsBackgroundService || _serviceConfigured) return;
    bool ok = false;
    try {
      ok = await _backgroundService.configure(
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: trackingBackgroundOnStart,
          onBackground: trackingIosBackground,
        ),
        androidConfiguration: AndroidConfiguration(
          onStart: trackingBackgroundOnStart,
          autoStart: false,
          autoStartOnBoot: false,
          isForegroundMode: true,
          initialNotificationTitle: 'Faixa Amarela',
          initialNotificationContent: 'Rota em andamento',
          foregroundServiceNotificationId: 74101,
          foregroundServiceTypes: const <AndroidForegroundType>[
            AndroidForegroundType.location,
          ],
        ),
      );
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          warning: 'Servico background indisponivel neste ambiente: $e',
        );
      }
      _serviceConfigured = false;
      return;
    }

    _serviceConfigured = ok;
    if (!ok) {
      if (ref.mounted) {
        state = state.copyWith(
          warning: 'Nao foi possivel configurar o servico de background.',
        );
      }
    }
  }

  void _listenBackgroundServiceEvents() {
    _bufferCountSubscription?.cancel();
    _flushSuccessSubscription?.cancel();
    _errorSubscription?.cancel();

    _bufferCountSubscription = _backgroundService
        .on(trackingEventBufferCount)
        .listen((payload) {
          final count = (payload?['count'] as num?)?.toInt() ?? 0;
          state = state.copyWith(pendingBufferCount: count);
        });

    _flushSuccessSubscription = _backgroundService
        .on(trackingEventFlushSuccess)
        .listen((payload) {
          final remaining = (payload?['remaining_count'] as num?)?.toInt();
          if (remaining != null) {
            state = state.copyWith(
              pendingBufferCount: remaining,
              clearError: true,
            );
          }
        });

    _errorSubscription = _backgroundService.on(trackingEventError).listen((
      payload,
    ) {
      final message = payload?['message']?.toString();
      if (message == null || message.isEmpty) return;
      state = state.copyWith(error: message);
    });
  }

  Future<void> _switchToForegroundMode() async {
    if (!state.routeActive) return;

    if (_supportsBackgroundService) {
      try {
        _backgroundService.invoke(trackingCommandSetMode, <String, dynamic>{
          'mode': 'foreground',
        });
      } catch (_) {}
    }

    await _startForegroundStream();
    state = state.copyWith(backgroundMode: false);
  }

  Future<void> _switchToBackgroundMode() async {
    if (!state.routeActive) return;

    await _stopForegroundStream();

    if (_supportsBackgroundService) {
      try {
        _backgroundService.invoke(trackingCommandSetMode, <String, dynamic>{
          'mode': 'background',
        });
      } catch (_) {}
    }

    state = state.copyWith(
      backgroundMode: true,
      foregroundStreaming: false,
      socketConnected: false,
    );
  }

  Future<void> _startForegroundStream() async {
    if (_foregroundPositionSubscription != null) return;

    final routeManifestId = state.routeManifestId ??
        (state.routeId != null && state.routeId! > 0
            ? 'route.${state.routeId}'
            : null);
    if (routeManifestId == null || routeManifestId.isEmpty) return;

    _foregroundPositionSubscription =
        Geolocator.getPositionStream(
          locationSettings: TrackingLocationSettingsFactory.foreground(),
        ).listen(
          (position) {
            _handleForegroundPosition(position);
          },
          onError: (Object error, StackTrace stackTrace) {
            state = state.copyWith(error: 'Erro no stream de GPS: $error');
          },
        );

    state = state.copyWith(foregroundStreaming: true, backgroundMode: false);
  }

  Future<void> _captureInitialPositionAndPrimeRoute() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: TrackingLocationSettingsFactory.foreground(),
      );
      if (!state.routeActive) return;
      _handleForegroundPosition(position);
    } catch (_) {
      // Primeiro fix pode demorar no iOS/simulador. O stream continuo cobre isso.
    }
  }

  Future<void> _stopForegroundStream() async {
    final sub = _foregroundPositionSubscription;
    _foregroundPositionSubscription = null;
    await sub?.cancel();
    state = state.copyWith(foregroundStreaming: false);
  }

  void _handleForegroundPosition(Position position) {
    final point = TrackingPointSerializer.fromPosition(position);

    state = state.copyWith(
      lastPointAt: DateTime.tryParse(point['timestamp'].toString()),
      lastLatitude: (point['lat'] as num?)?.toDouble(),
      lastLongitude: (point['lng'] as num?)?.toDouble(),
      lastSpeedKmh: (point['speed'] as num?)?.toInt(),
      lastHeading: (point['heading'] as num?)?.toInt(),
      clearError: true,
    );

    _appendForegroundPointToTelemetryBuffer(point);
    unawaited(_performGeofenceCheck(position));
    unawaited(_checkOffRouteAndMaybeRecalculate(position));
    unawaited(_performRoutePreviewRefresh(position));
  }

  Future<void> _checkOffRouteAndMaybeRecalculate(Position position) async {
    final polyline = state.routePolyline;
    if (polyline.length < 2) {
      _offRouteSince = null;
      return;
    }

    final now = DateTime.now();
    final distanceMeters = _distancePointToPolylineMeters(
      latitude: position.latitude,
      longitude: position.longitude,
      polyline: polyline,
    );

    if (!distanceMeters.isFinite ||
        distanceMeters <= _deviationDistanceThresholdMeters) {
      _offRouteSince = null;
      if (state.offRoute || state.routeRecalculating) {
        state = state.copyWith(offRoute: false, routeRecalculating: false);
      }
      return;
    }

    _offRouteSince ??= now;
    if (!state.offRoute) {
      state = state.copyWith(offRoute: true);
    }

    if (now.difference(_offRouteSince!) <
        Duration(seconds: _deviationSustainSeconds)) {
      return;
    }

    if (_lastDeviationRecalcAt != null &&
        now.difference(_lastDeviationRecalcAt!) <
            Duration(seconds: _deviationDebounceSeconds)) {
      return;
    }

    _lastDeviationRecalcAt = now;
    _offRouteSince = null;
    state = state.copyWith(offRoute: true, routeRecalculating: true);
    await _performRoutePreviewRefresh(position, force: true);
  }

  void _appendForegroundPointToTelemetryBuffer(Map<String, dynamic> point) {
    if (!_supportsBackgroundService || !_serviceConfigured) {
      return;
    }

    try {
      _backgroundService.invoke(trackingCommandAppendPoint, point);
    } catch (_) {}
  }

  Future<void> _performGeofenceCheck(Position position) async {
    if (_isGeofenceRequestInFlight) return;
    if (!state.routeActive) return;
    if (_authHeader == null || _authHeader!.isEmpty) return;
    final routeManifestId = state.routeManifestId ??
        (state.routeId != null && state.routeId! > 0
            ? 'route.${state.routeId}'
            : null);
    if (routeManifestId == null || routeManifestId.isEmpty) return;

    final now = DateTime.now();
    if (_lastGeofenceCheckAt != null &&
        now.difference(_lastGeofenceCheckAt!) < const Duration(seconds: 10)) {
      return;
    }

    _isGeofenceRequestInFlight = true;
    _lastGeofenceCheckAt = now;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/driver/geofences/check',
        data: <String, dynamic>{
          'lat': position.latitude,
          'lng': position.longitude,
          // Backend passa a honrar radiusMeters/limit e derivou a rota do
          // token — routeId/routeManifestId saíram do contrato (400 via
          // whitelist se enviados).
          'radiusMeters': state.geofenceRadiusMeters,
          'limit': 10,
        },
        options: Options(
          headers: <String, dynamic>{'Authorization': _authHeader},
        ),
      );

      final data = response.data ?? const <String, dynamic>{};
      final matches = (data['matches'] as List?) ?? const <dynamic>[];
      final nearest = matches.isNotEmpty && matches.first is Map
          ? Map<String, dynamic>.from(matches.first as Map)
          : null;

      state = state.copyWith(
        nearbyCount: (data['count'] as num?)?.toInt() ?? matches.length,
        nearestChildName: nearest?['childName']?.toString(),
        nearestDistanceMeters: (nearest?['distanceMeters'] as num?)
            ?.toDouble(),
      );
    } catch (e) {
      // Geofence é auxiliar; falhas de rede não devem derrubar o tracking.
      // APP-28: logar em vez de engolir silenciosamente.
      debugPrint('[DriverTrackingController] geofence check falhou: $e');
    } finally {
      _isGeofenceRequestInFlight = false;
    }
  }

  Future<void> _performRoutePreviewRefresh(
    Position position, {
    bool force = false,
  }) async {
    if (_isRouteRecalcInFlight) return;
    if (!state.routeActive) return;
    if (_authHeader == null || _authHeader!.isEmpty) return;
    final routeManifestId = state.routeManifestId ??
        (state.routeId != null && state.routeId! > 0
            ? 'route.${state.routeId}'
            : null);
    if (routeManifestId == null || routeManifestId.isEmpty) return;

    final now = DateTime.now();
    final hasRouteVisual =
        state.routePolyline.length >= 2 ||
        state.routeRemainingStops.isNotEmpty ||
        ((state.routeDistanceMeters ?? 0) > 0);
    final minInterval = hasRouteVisual
        ? const Duration(seconds: 15)
        : const Duration(seconds: 3);
    if (!force &&
        _lastRouteRecalcAt != null &&
        now.difference(_lastRouteRecalcAt!) < minInterval) {
      return;
    }

    _isRouteRecalcInFlight = true;
    _lastRouteRecalcAt = now;

    try {
      final routeId = state.routeId;
      if (routeId == null || routeId <= 0) {
        state = state.copyWith(
          routeRecalculating: false,
          warning: 'Rota não identificada para recálculo.',
        );
        return;
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/driver/routes/$routeId/recalculate',
        data: <String, dynamic>{
          'lat': position.latitude,
          'lng': position.longitude,
        },
        options: Options(
          headers: <String, dynamic>{'Authorization': _authHeader},
        ),
      );

      final data = response.data ?? const <String, dynamic>{};
      final distance = (data['distanceMeters'] as num?)?.toDouble();
      final duration = (data['durationSeconds'] as num?)?.toInt();

      final remainingStops = (data['remainingStops'] as List?) ?? const [];
      final stops = _parseStops(remainingStops);

      final polyline = _extractPolylinePoints(data['geometry']);

      final mapUrl = _buildExternalDirectionsUrl(
        originLat: position.latitude,
        originLng: position.longitude,
        stops: stops
            .map((s) => (name: s.name, lat: s.lat, lng: s.lng))
            .toList(growable: false),
      );

      state = state.copyWith(
        routeDistanceMeters: distance,
        routeEtaSeconds: duration,
        routePreviewMapUrl: mapUrl,
        routePreviewUpdatedAt: now,
        routeNextStopName: stops.isNotEmpty ? stops.first.name : null,
        routePolyline: polyline,
        routeRemainingStops: stops,
        routePlannedStops: _mergePlannedStops(
          previous: state.routePlannedStops,
          incomingRemaining: stops,
        ),
        offRoute: false,
        routeRecalculating: false,
        clearWarning: true,
      );
    } catch (e) {
      final message = _extractRouteRecalcErrorMessage(e);
      state = state.copyWith(
        routeRecalculating: false,
        warning: message == null
            ? state.warning
            : 'Rota nao foi atualizada agora: $message',
      );
    } finally {
      _isRouteRecalcInFlight = false;
    }
  }

  Future<bool> _ensureTrackingPermissions() async {
    final locationGranted = await _ensureLocationPermissions();
    if (!locationGranted) return false;

    await _ensureNotificationPermission();
    return true;
  }

  Future<bool> _ensureLocationPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(
        warning: 'Ative a localizacao do aparelho para iniciar a rota.',
      );
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (_usesMobileBackgroundLocation &&
        permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }

    final locationGranted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    final backgroundGranted =
        !_usesMobileBackgroundLocation ||
        permission == LocationPermission.always;

    final warning = switch (permission) {
      LocationPermission.deniedForever =>
        'Permissao de localizacao bloqueada. Abra as configuracoes do app para liberar.',
      LocationPermission.denied =>
        'Permita o acesso a localizacao para iniciar a rota.',
      LocationPermission.whileInUse when !backgroundGranted =>
        'Para manter a rota com a tela bloqueada, permita localizacao o tempo todo nas configuracoes do app.',
      _ => null,
    };

    state = state.copyWith(
      permissionsGranted: locationGranted,
      warning: warning,
      clearWarning: warning == null,
    );

    return locationGranted;
  }

  bool get _usesMobileBackgroundLocation =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<bool> _ensureNotificationPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      final granted = await _permissionsChannel.invokeMethod<bool>(
        'requestNotifications',
      );
      if (granted == false && ref.mounted) {
        state = state.copyWith(
          warning:
              'Permita notificacoes para acompanhar a rota em segundo plano.',
        );
      }
      return granted ?? true;
    } on MissingPluginException {
      return true;
    } on PlatformException catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          warning: 'Nao foi possivel pedir permissao de notificacao agora.',
        );
      }
      return false;
    }
  }

  Future<bool> requestBackgroundLocationSettings() async {
    if (!_usesMobileBackgroundLocation) return true;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always) return true;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return Geolocator.openAppSettings();
    }

    if (permission == LocationPermission.whileInUse) {
      final requested = await Geolocator.requestPermission();
      return requested == LocationPermission.always;
    }

    return _ensureLocationPermissions();
  }

  // Realtime via WebSocket foi desabilitado após remoção do pusher_channels_flutter.
  // O app continua enviando coordenadas via background service e API REST;
  // o socket só seria usado para whispers de localização em tempo real.

  String? _extractRouteRecalcErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        final text = data['message'].toString().trim();
        if (text.isNotEmpty) return text;
      }
      final text = error.message?.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    final text = error.toString().trim();
    if (text.isEmpty) return null;
    return text;
  }

  /// Link externo de rota baseado em OpenStreetMap/OSRM (sem Google Maps).
  /// O preview in-app usa a geometria ORS via [state.routePolyline] no MapLibre;
  /// este link serve apenas como "abrir no mapa externo".
  String? _buildExternalDirectionsUrl({
    required double originLat,
    required double originLng,
    required List<({String? name, double? lat, double? lng})> stops,
  }) {
    final valid = stops
        .where((s) => s.lat != null && s.lng != null)
        .toList(growable: false);
    if (valid.isEmpty) return null;

    final waypoints = <String>['$originLat,$originLng'];
    for (final s in valid.take(6)) {
      waypoints.add('${s.lat},${s.lng}');
    }

    return Uri.https('www.openstreetmap.org', '/directions', <String, String>{
      'engine': 'fossgis_osrm_car',
      'route': waypoints.join(';'),
    }).toString();
  }

  List<DriverTrackingLatLng> _extractPolylinePoints(dynamic geometry) {
    final out = _extractPolylinePointsAny(geometry);
    if (out.length < 2) return const [];
    return out;
  }

  List<DriverTrackingLatLng> _extractPolylinePointsAny(dynamic geometry) {
    if (geometry == null) return const [];

    if (geometry is String) {
      final trimmed = geometry.trim();
      if (trimmed.isEmpty) return const [];
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          return _extractPolylinePointsAny(jsonDecode(trimmed));
        } catch (_) {
          // Falls back to encoded polyline parsing below.
        }
      }
      return _decodeEncodedPolyline(trimmed);
    }

    if (geometry is List) {
      return _pointsFromCoordinateList(geometry);
    }

    if (geometry is! Map) return const [];

    if (geometry['geometry'] != null) {
      final nested = _extractPolylinePointsAny(geometry['geometry']);
      if (nested.length >= 2) return nested;
    }

    if (geometry['polyline'] is String) {
      final decoded = _decodeEncodedPolyline(geometry['polyline'].toString());
      if (decoded.length >= 2) return decoded;
    }

    final type = geometry['type']?.toString().toLowerCase();
    switch (type) {
      case 'feature':
        return _extractPolylinePointsAny(geometry['geometry']);
      case 'featurecollection':
        final features = geometry['features'];
        if (features is! List) return const [];
        final merged = <DriverTrackingLatLng>[];
        for (final feature in features) {
          final points = _extractPolylinePointsAny(feature);
          if (points.isEmpty) continue;
          if (merged.isNotEmpty &&
              points.isNotEmpty &&
              merged.last.lat == points.first.lat &&
              merged.last.lng == points.first.lng) {
            merged.addAll(points.skip(1));
          } else {
            merged.addAll(points);
          }
        }
        return merged;
      case 'multilinestring':
        final coords = geometry['coordinates'];
        if (coords is! List) return const [];
        final merged = <DriverTrackingLatLng>[];
        for (final segment in coords) {
          final points = _pointsFromCoordinateList(segment);
          if (points.isEmpty) continue;
          if (merged.isNotEmpty &&
              merged.last.lat == points.first.lat &&
              merged.last.lng == points.first.lng) {
            merged.addAll(points.skip(1));
          } else {
            merged.addAll(points);
          }
        }
        return merged;
      case 'linestring':
        return _pointsFromCoordinateList(geometry['coordinates']);
      default:
        if (geometry['coordinates'] is List) {
          return _pointsFromCoordinateList(geometry['coordinates']);
        }
        return const [];
    }
  }

  List<DriverTrackingLatLng> _pointsFromCoordinateList(dynamic coordinates) {
    if (coordinates is! List) return const [];
    final points = <DriverTrackingLatLng>[];
    for (final item in coordinates) {
      if (item is! List || item.length < 2) continue;
      final lng = item[0];
      final lat = item[1];
      if (lat is num && lng is num) {
        points.add((lat: lat.toDouble(), lng: lng.toDouble()));
      }
    }
    return points;
  }

  List<DriverTrackingLatLng> _decodeEncodedPolyline(String encoded) {
    if (encoded.isEmpty) return const [];
    final points = <DriverTrackingLatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      final latResult = _decodePolylineChunk(encoded, index);
      if (latResult == null) break;
      index = latResult.nextIndex;
      lat += latResult.delta;

      final lngResult = _decodePolylineChunk(encoded, index);
      if (lngResult == null) break;
      index = lngResult.nextIndex;
      lng += lngResult.delta;

      points.add((lat: lat / 1e5, lng: lng / 1e5));
    }

    return points;
  }

  ({int delta, int nextIndex})? _decodePolylineChunk(
    String encoded,
    int start,
  ) {
    var result = 0;
    var shift = 0;
    var index = start;

    while (index < encoded.length) {
      final byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
      if (byte < 0x20) {
        final delta = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
        return (delta: delta, nextIndex: index);
      }
    }

    return null;
  }

  double _distancePointToPolylineMeters({
    required double latitude,
    required double longitude,
    required List<DriverTrackingLatLng> polyline,
  }) {
    if (polyline.length < 2) return double.infinity;

    final latRad = latitude * math.pi / 180.0;
    const earthRadius = 6371000.0;

    double projectX(double lng) =>
        (lng - longitude) * math.pi / 180.0 * earthRadius * math.cos(latRad);
    double projectY(double lat) =>
        (lat - latitude) * math.pi / 180.0 * earthRadius;

    var best = double.infinity;
    for (var i = 0; i < polyline.length - 1; i++) {
      final a = polyline[i];
      final b = polyline[i + 1];
      final ax = projectX(a.lng);
      final ay = projectY(a.lat);
      final bx = projectX(b.lng);
      final by = projectY(b.lat);
      final distance = _distancePointToSegmentMeters(
        px: 0,
        py: 0,
        ax: ax,
        ay: ay,
        bx: bx,
        by: by,
      );
      if (distance < best) best = distance;
    }

    return best;
  }

  double _distancePointToSegmentMeters({
    required double px,
    required double py,
    required double ax,
    required double ay,
    required double bx,
    required double by,
  }) {
    final abx = bx - ax;
    final aby = by - ay;
    final apx = px - ax;
    final apy = py - ay;
    final abLenSquared = (abx * abx) + (aby * aby);

    if (abLenSquared <= 0.000001) {
      return math.sqrt((apx * apx) + (apy * apy));
    }

    final projection = ((apx * abx) + (apy * aby)) / abLenSquared;
    final t = projection.clamp(0.0, 1.0);
    final closestX = ax + (abx * t);
    final closestY = ay + (aby * t);
    final dx = px - closestX;
    final dy = py - closestY;
    return math.sqrt((dx * dx) + (dy * dy));
  }

  List<DriverTrackingStopPoint> _parseStops(List<dynamic> rawStops) {
    return rawStops
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map((map) {
          final lat = (map['latitude'] as num?)?.toDouble() ??
              (map['lat'] as num?)?.toDouble();
          final lng = (map['longitude'] as num?)?.toDouble() ??
              (map['lng'] as num?)?.toDouble();
          if (lat == null || lng == null) return null;
          return (
            id: map['id']?.toString(),
            clientId: (map['clientId'] as num?)?.toInt(),
            childId: (map['childId'] as num?)?.toInt(),
            type: map['type']?.toString(),
            status: (map['status'] ?? 'pending').toString(),
            sequence:
                (map['sequence'] as num?)?.toInt() ??
                (map['order'] as num?)?.toInt(),
            lat: lat,
            lng: lng,
            name: map['name']?.toString(),
          );
        })
        .whereType<DriverTrackingStopPoint>()
        .toList(growable: false);
  }

  List<DriverTrackingStopPoint> _mergePlannedStops({
    required List<DriverTrackingStopPoint> previous,
    required List<DriverTrackingStopPoint> incomingRemaining,
  }) {
    if (previous.isEmpty) return incomingRemaining;

    final remainingById = <String, DriverTrackingStopPoint>{};
    for (final stop in incomingRemaining) {
      final key = stop.id ?? _stopFallbackKey(stop);
      remainingById[key] = stop;
    }

    final merged = <DriverTrackingStopPoint>[];
    for (final stop in previous) {
      final key = stop.id ?? _stopFallbackKey(stop);
      final latest = remainingById.remove(key);
      if (latest != null) {
        merged.add(latest);
      } else {
        final currentStatus = stop.status.toLowerCase();
        final completedStatus = _resolveCompletedStatus(stop.type);
        merged.add((
          id: stop.id,
          clientId: stop.clientId,
          childId: stop.childId,
          type: stop.type,
          status: (currentStatus == 'pending' || currentStatus == 'a_caminho')
              ? completedStatus
              : stop.status,
          sequence: stop.sequence,
          lat: stop.lat,
          lng: stop.lng,
          name: stop.name,
        ));
      }
    }

    if (remainingById.isNotEmpty) {
      final extras = remainingById.values.toList()
        ..sort(
          (a, b) => (a.sequence ?? 999999).compareTo(b.sequence ?? 999999),
        );
      merged.addAll(extras);
    }

    merged.sort(
      (a, b) => (a.sequence ?? 999999).compareTo(b.sequence ?? 999999),
    );
    return merged;
  }

  void _applyClientStopStatusLocal({
    required int childId,
    required Set<String> targetTypes,
    required String nextStatus,
  }) {
    final planned = [...state.routePlannedStops];
    var changed = false;
    for (var i = 0; i < planned.length; i++) {
      final stop = planned[i];
      if ((stop.childId ?? 0) != childId) continue;
      if (!targetTypes.contains(_normalizedStopType(stop.type))) continue;
      final current = stop.status.toLowerCase();
      if (current == 'delivered' || current == 'done') continue;
      planned[i] = (
        id: stop.id,
        clientId: stop.clientId,
        childId: stop.childId,
        type: stop.type,
        status: nextStatus,
        sequence: stop.sequence,
        lat: stop.lat,
        lng: stop.lng,
        name: stop.name,
      );
      changed = true;
      break;
    }
    if (!changed) return;

    final remaining = planned
        .where((s) {
          final status = s.status.toLowerCase();
          return status != 'picked_up' &&
              status != 'delivered' &&
              status != 'done';
        })
        .toList(growable: false);

    state = state.copyWith(
      routePlannedStops: planned,
      routeRemainingStops: remaining,
      routeNextStopName: remaining.isNotEmpty ? remaining.first.name : null,
    );
  }

  static final _pickupTypes = <String>{
    'pickup',
    'pickup_home',
    'pickup_school',
  };

  static final _dropoffTypes = <String>{
    'dropoff',
    'dropoff_home',
    'dropoff_school',
  };

  static bool _isPickupType(String? type) =>
      _pickupTypes.contains(_normalizedStopType(type));

  static bool _isDropoffType(String? type) =>
      _dropoffTypes.contains(_normalizedStopType(type));

  static String _normalizedStopType(String? type) =>
      (type ?? '').toLowerCase().trim();

  static String _resolveCompletedStatus(String? type) {
    if (_isPickupType(type)) return 'picked_up';
    if (_isDropoffType(type)) return 'delivered';
    return 'done';
  }

  String _stopFallbackKey(DriverTrackingStopPoint stop) {
    return [
      stop.clientId?.toString() ?? '',
      stop.childId?.toString() ?? '',
      stop.type ?? '',
      stop.sequence?.toString() ?? '',
      stop.lat.toStringAsFixed(6),
      stop.lng.toStringAsFixed(6),
    ].join('|');
  }
}
