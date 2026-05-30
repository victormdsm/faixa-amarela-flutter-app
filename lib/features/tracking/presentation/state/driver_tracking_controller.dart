import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

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
      _disconnectRealtimeSocket();
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

  PusherChannelsFlutter? _pusher;
  PusherChannel? _privateTelemetryChannel;
  String? _subscribedPrivateChannelName;

  String? _authHeader;
  bool _initialized = false;
  bool _serviceConfigured = false;
  bool _isGeofenceRequestInFlight = false;
  DateTime? _lastGeofenceCheckAt;
  bool _isRouteRecalcInFlight = false;
  DateTime? _lastRouteRecalcAt;

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
      _backgroundService.invoke(trackingCommandUpdateAuth, <String, dynamic>{
        'auth_header': _authHeader,
      });
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
    );
    _lastRouteRecalcAt = null;
    _isRouteRecalcInFlight = false;

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
      } catch (e) {
        state = state.copyWith(warning: 'Servico background indisponivel: $e');
      }
    }

    await _connectRealtimeSocket(session, routeManifestId, vanId);
    await _captureInitialPositionAndPrimeRoute();
    await _switchToForegroundMode();
    return true;
  }

  Future<void> stopRouteTracking({bool silent = false}) async {
    await _stopForegroundStream();
    await _disconnectRealtimeSocket();

    if (_supportsBackgroundService) {
      try {
        _backgroundService.invoke(trackingCommandStop);
      } catch (_) {}
    }

    _lastRouteRecalcAt = null;
    _isRouteRecalcInFlight = false;
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
        ? _buildGoogleDirectionsUrl(
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

  void markClientBoardedLocal(int clientId) {
    _applyClientStopStatusLocal(
      clientId: clientId,
      targetTypes: const {'pickup_home', 'pickup_school'},
      nextStatus: 'picked_up',
    );
  }

  void markClientDisembarkedLocal(int clientId) {
    _applyClientStopStatusLocal(
      clientId: clientId,
      targetTypes: const {'dropoff_home', 'dropoff_school'},
      nextStatus: 'delivered',
    );
  }

  /// Remove all stops for a given client from local state.
  void removeClientLocal(int clientId) {
    final planned = state.routePlannedStops
        .where((s) => (s.clientId ?? 0) != clientId)
        .toList(growable: false);

    final remaining = planned
        .where((s) {
          final status = s.status.toLowerCase();
          return status != 'delivered' && status != 'done';
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
      _backgroundService.invoke(trackingCommandSetMode, <String, dynamic>{
        'mode': 'foreground',
      });
    }

    await _startForegroundStream();
    state = state.copyWith(backgroundMode: false);
  }

  Future<void> _switchToBackgroundMode() async {
    if (!state.routeActive) return;

    await _stopForegroundStream();
    await _disconnectRealtimeSocket();

    if (_supportsBackgroundService) {
      _backgroundService.invoke(trackingCommandSetMode, <String, dynamic>{
        'mode': 'background',
      });
    }

    state = state.copyWith(
      backgroundMode: true,
      foregroundStreaming: false,
      socketConnected: false,
    );
  }

  Future<void> _startForegroundStream() async {
    if (_foregroundPositionSubscription != null) return;

    if (state.routeManifestId == null) return;

    if (_authHeader != null && _authHeader!.isNotEmpty) {
      await _connectRealtimeSocketIfNeeded(
        authorizationHeader: _authHeader!,
        routeManifestId: state.routeManifestId!,
        vanId: state.vanId,
      );
    }

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
    _publishRealtimeLocationWhisper(point);
    unawaited(_performGeofenceCheck(position));
    unawaited(_performRoutePreviewRefresh(position));
  }

  void _appendForegroundPointToTelemetryBuffer(Map<String, dynamic> point) {
    if (!_supportsBackgroundService || !_serviceConfigured) {
      return;
    }

    _backgroundService.invoke(trackingCommandAppendPoint, point);
  }

  Future<void> _performGeofenceCheck(Position position) async {
    if (_isGeofenceRequestInFlight) return;
    if (!state.routeActive || state.routeManifestId == null) return;
    if (_authHeader == null || _authHeader!.isEmpty) return;

    final now = DateTime.now();
    if (_lastGeofenceCheckAt != null &&
        now.difference(_lastGeofenceCheckAt!) < const Duration(seconds: 10)) {
      return;
    }

    _isGeofenceRequestInFlight = true;
    _lastGeofenceCheckAt = now;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/drivers/geofences/check',
        data: <String, dynamic>{
          'lat': position.latitude,
          'lng': position.longitude,
          'route_manifest_id': state.routeManifestId,
          'radius_meters': state.geofenceRadiusMeters,
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
        nearestChildName: nearest?['child_name']?.toString(),
        nearestDistanceMeters: (nearest?['distance_meters'] as num?)
            ?.toDouble(),
      );
    } catch (_) {
      // Geofence é auxiliar; falhas de rede não devem derrubar o tracking.
    } finally {
      _isGeofenceRequestInFlight = false;
    }
  }

  Future<void> _performRoutePreviewRefresh(Position position) async {
    if (_isRouteRecalcInFlight) return;
    if (!state.routeActive || state.routeManifestId == null) return;
    if (_authHeader == null || _authHeader!.isEmpty) return;

    final now = DateTime.now();
    final hasRouteVisual =
        state.routePolyline.length >= 2 ||
        state.routeRemainingStops.isNotEmpty ||
        ((state.routeDistanceMeters ?? 0) > 0);
    final minInterval = hasRouteVisual
        ? const Duration(seconds: 15)
        : const Duration(seconds: 3);
    if (_lastRouteRecalcAt != null &&
        now.difference(_lastRouteRecalcAt!) < minInterval) {
      return;
    }

    _isRouteRecalcInFlight = true;
    _lastRouteRecalcAt = now;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/drivers/route/recalculate',
        data: <String, dynamic>{
          'route_manifest_id': state.routeManifestId,
          'lat': position.latitude,
          'lng': position.longitude,
        },
        options: Options(
          headers: <String, dynamic>{'Authorization': _authHeader},
        ),
      );

      final data = response.data ?? const <String, dynamic>{};
      final distance = (data['distance_meters'] as num?)?.toDouble();
      final duration = (data['duration_seconds'] as num?)?.toInt();

      final remainingStops = (data['remaining_stops'] as List?) ?? const [];
      final stops = _parseStops(remainingStops);

      final polyline = _extractPolylinePoints(data['geometry']);

      final mapUrl = _buildGoogleDirectionsUrl(
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
      );
    } catch (e) {
      final message = _extractRouteRecalcErrorMessage(e);
      state = state.copyWith(
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

  Future<void> _connectRealtimeSocket(
    AuthSession session,
    String routeManifestId,
    int? vanId,
  ) async {
    await _connectRealtimeSocketIfNeeded(
      authorizationHeader: session.authorizationHeader,
      routeManifestId: routeManifestId,
      vanId: vanId,
    );
  }

  Future<void> _connectRealtimeSocketIfNeeded({
    required String authorizationHeader,
    required String routeManifestId,
    int? vanId,
  }) async {
    if (!_supportsBackgroundService ||
        !(defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      return;
    }

    if (BackendConfig.pusherAppKey.isEmpty) {
      state = state.copyWith(
        socketConnected: false,
        warning:
            'Socket Reverb/Pusher desabilitado (PUSHER_APP_KEY nao configurado no app).',
      );
      return;
    }

    final privateChannelName = _buildTelemetryChannelName(
      routeManifestId: routeManifestId,
      vanId: vanId,
    );
    final pusherChannelName = 'private-$privateChannelName';

    if (state.socketConnected &&
        _privateTelemetryChannel != null &&
        _subscribedPrivateChannelName == privateChannelName) {
      return;
    }

    try {
      await _disconnectRealtimeSocket();

      final pusher = PusherChannelsFlutter.getInstance();
      await pusher.init(
        apiKey: BackendConfig.pusherAppKey,
        cluster: BackendConfig.pusherCluster.isEmpty
            ? null
            : BackendConfig.pusherCluster,
        host: BackendConfig.pusherHost,
        wsPort: BackendConfig.pusherPort,
        wssPort: BackendConfig.pusherPort,
        useTLS: BackendConfig.pusherEncrypted,
        onConnectionStateChange: (currentState, previousState) {
          _handlePusherConnectionStateChange(
            currentState: currentState,
            previousState: previousState,
          );
        },
        onSubscriptionSucceeded: (channelName, _) {
          if (channelName == pusherChannelName) {
            state = state.copyWith(socketConnected: true, clearWarning: true);
          }
        },
        onSubscriptionError: (message, error) {
          state = state.copyWith(
            socketConnected: false,
            warning:
                'Falha ao assinar canal realtime: ${_normalizeRealtimeError(message, error)}',
          );
        },
        onError: (message, code, error) {
          final suffix = code == null ? '' : ' (codigo $code)';
          state = state.copyWith(
            socketConnected: false,
            warning:
                'Falha no socket Reverb/Pusher$suffix: ${_normalizeRealtimeError(message, error)}',
          );
        },
        onAuthorizer: (channelName, socketId, options) {
          return _authorizePusherChannel(
            authorizationHeader: authorizationHeader,
            channelName: channelName,
            socketId: socketId,
          );
        },
      );

      _privateTelemetryChannel = await pusher.subscribe(
        channelName: pusherChannelName,
      );
      _pusher = pusher;
      await pusher.connect();
      _subscribedPrivateChannelName = privateChannelName;
      state = state.copyWith(clearWarning: true);
    } catch (e) {
      state = state.copyWith(
        socketConnected: false,
        warning: 'Nao foi possivel conectar ao Reverb/Pusher: $e',
      );
    }
  }

  void _publishRealtimeLocationWhisper(Map<String, dynamic> point) {
    final channel = _privateTelemetryChannel;
    if (channel == null) return;

    try {
      final payload = <String, dynamic>{
        'lat': point['lat'],
        'lng': point['lng'],
        'speed': point['speed'],
        'heading': point['heading'],
        'timestamp': point['timestamp'],
        'route_manifest_id': state.routeManifestId,
        'van_id': state.vanId,
      };
      unawaited(
        channel.trigger(
          PusherEvent(
            channelName: channel.channelName,
            eventName: 'client-location',
            data: jsonEncode(payload),
          ),
        ),
      );
    } catch (e) {
      state = state.copyWith(
        socketConnected: false,
        warning: 'Falha ao enviar coordenada por socket: $e',
      );
    }
  }

  Future<void> _disconnectRealtimeSocket() async {
    try {
      final pusher = _pusher;
      if (pusher != null && _subscribedPrivateChannelName != null) {
        await pusher.unsubscribe(
          channelName: 'private-${_subscribedPrivateChannelName!}',
        );
      }
      await pusher?.disconnect();
    } catch (_) {
      // noop
    } finally {
      _privateTelemetryChannel = null;
      _subscribedPrivateChannelName = null;
      _pusher = null;
      if (ref.mounted) {
        state = state.copyWith(socketConnected: false);
      }
    }
  }

  String _buildTelemetryChannelName({
    required String routeManifestId,
    required int? vanId,
  }) {
    if (vanId != null && vanId > 0) {
      return 'van.$vanId';
    }
    return 'telemetry.route.$routeManifestId';
  }

  Future<Map<String, String>> _authorizePusherChannel({
    required String authorizationHeader,
    required String channelName,
    required String socketId,
  }) async {
    final response = await _dio.post<dynamic>(
      BackendConfig.pusherAuthEndpoint,
      data: <String, dynamic>{
        'socket_id': socketId,
        'channel_name': channelName,
      },
      options: Options(
        headers: <String, dynamic>{
          'Authorization': authorizationHeader,
          'Accept': 'application/json',
        },
      ),
    );

    final payload = _decodePusherAuthResponse(response.data);
    final auth = payload['auth']?.toString().trim();
    if (auth == null || auth.isEmpty) {
      throw const FormatException('Resposta de auth do Pusher sem campo auth.');
    }

    final result = <String, String>{'auth': auth};
    final channelData = payload['channel_data']?.toString();
    if (channelData != null && channelData.isNotEmpty) {
      result['channel_data'] = channelData;
    }
    final sharedSecret = payload['shared_secret']?.toString();
    if (sharedSecret != null && sharedSecret.isNotEmpty) {
      result['shared_secret'] = sharedSecret;
    }
    return result;
  }

  Map<String, dynamic> _decodePusherAuthResponse(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String && data.trim().isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }
    throw const FormatException('Resposta invalida da autenticacao Pusher.');
  }

  void _handlePusherConnectionStateChange({
    required String currentState,
    required String previousState,
  }) {
    final normalizedCurrent = currentState.toUpperCase();
    final normalizedPrevious = previousState.toUpperCase();

    if (normalizedCurrent == 'CONNECTED') {
      state = state.copyWith(socketConnected: true, clearError: true);
      return;
    }

    if (normalizedCurrent == 'DISCONNECTED') {
      state = state.copyWith(socketConnected: false);
      return;
    }

    if (normalizedCurrent == 'FAILED') {
      state = state.copyWith(
        socketConnected: false,
        warning:
            'Conexao realtime falhou (estado: $normalizedPrevious -> $normalizedCurrent).',
      );
      return;
    }

    state = state.copyWith(socketConnected: false);
  }

  String _normalizeRealtimeError(dynamic message, dynamic error) {
    final messageText = message?.toString().trim() ?? '';
    if (messageText.isNotEmpty) return messageText;
    final errorText = error?.toString().trim() ?? '';
    if (errorText.isNotEmpty) return errorText;
    return 'erro desconhecido';
  }

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

  String? _buildGoogleDirectionsUrl({
    required double originLat,
    required double originLng,
    required List<({String? name, double? lat, double? lng})> stops,
  }) {
    if (stops.isEmpty) return null;
    final first = stops.first;
    if (first.lat == null || first.lng == null) return null;

    final params = <String, String>{
      'api': '1',
      'travelmode': 'driving',
      'origin': '$originLat,$originLng',
      'destination': '${first.lat},${first.lng}',
    };

    if (stops.length > 1) {
      final waypoints = stops
          .skip(1)
          .take(5)
          .where((s) => s.lat != null && s.lng != null)
          .map((s) => '${s.lat},${s.lng}')
          .join('|');
      if (waypoints.isNotEmpty) {
        params['waypoints'] = waypoints;
      }
    }

    return Uri.https('www.google.com', '/maps/dir/', params).toString();
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

  List<DriverTrackingStopPoint> _parseStops(List<dynamic> rawStops) {
    return rawStops
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map((map) {
          final lat = (map['lat'] as num?)?.toDouble();
          final lng = (map['lng'] as num?)?.toDouble();
          if (lat == null || lng == null) return null;
          return (
            id: map['id']?.toString(),
            clientId: (map['client_id'] as num?)?.toInt(),
            childId: (map['child_id'] as num?)?.toInt(),
            type: map['type']?.toString(),
            status: (map['status'] ?? 'pending').toString(),
            sequence: (map['sequence'] as num?)?.toInt(),
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
        final completedStatus = switch (stop.type) {
          'pickup_home' || 'pickup_school' => 'picked_up',
          'dropoff_home' || 'dropoff_school' => 'delivered',
          _ => 'done',
        };
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
    required int clientId,
    required Set<String> targetTypes,
    required String nextStatus,
  }) {
    final planned = [...state.routePlannedStops];
    var changed = false;
    for (var i = 0; i < planned.length; i++) {
      final stop = planned[i];
      if ((stop.clientId ?? 0) != clientId) continue;
      if (!targetTypes.contains((stop.type ?? '').toLowerCase())) continue;
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
          return status != 'delivered' && status != 'done';
        })
        .toList(growable: false);

    state = state.copyWith(
      routePlannedStops: planned,
      routeRemainingStops: remaining,
      routeNextStopName: remaining.isNotEmpty ? remaining.first.name : null,
    );
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
