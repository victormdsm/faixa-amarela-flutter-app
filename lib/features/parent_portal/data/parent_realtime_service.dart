import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Status da conexão realtime do acompanhamento do pai.
enum ParentRealtimeStatus { disconnected, connecting, connected }

/// Posição da van recebida via socket no evento `telemetry.location.updated`.
class ParentVanLocation {
  const ParentVanLocation({
    required this.latitude,
    required this.longitude,
    this.routeId,
    this.at,
    this.speedKmh,
    this.heading,
  });

  final double latitude;
  final double longitude;
  final int? routeId;
  final DateTime? at;
  final double? speedKmh;
  final double? heading;
}

/// Mudança de status da rota recebida via socket no evento
/// `route.status.updated` (payload: routeId, manifestId, userId, status).
class ParentRouteStatusEvent {
  const ParentRouteStatusEvent({this.routeId, this.status});

  final int? routeId;
  final String? status;
}

/// Mudança de embarque recebida via socket no evento
/// `boarding.status.updated` (payload: routeId, manifestId, childId, status).
class ParentBoardingStatusEvent {
  const ParentBoardingStatusEvent({this.routeId, this.childId, this.status});

  final int? routeId;
  final int? childId;
  final String? status;
}

/// Abstração mínima sobre o socket para permitir um fake em testes (o
/// `Socket` concreto do socket_io_client não é injetável sem abrir conexão).
abstract interface class ParentRealtimeSocket {
  bool get connected;
  void connect();
  void onConnect(void Function(dynamic data) handler);
  void onDisconnect(void Function(dynamic data) handler);
  void onConnectError(void Function(dynamic data) handler);
  void on(String event, void Function(dynamic data) handler);
  void off(String event);
  void emit(String event, Map<String, dynamic> data);
  void emitWithAck(
    String event,
    Map<String, dynamic> data, {
    void Function(dynamic response)? ack,
  });
  void dispose();
}

class _SocketIoSocket implements ParentRealtimeSocket {
  _SocketIoSocket({required String baseUrl, required String token})
    : _socket = io.io(
        baseUrl,
        io.OptionBuilder()
            // O gateway Nest (realtime.gateway.ts) valida o JWT em
            // handshake.auth.token e usa o path padrão /socket.io.
            .setTransports(<String>['websocket'])
            .setAuth(<String, dynamic>{'token': token})
            .enableReconnection()
            .build(),
      );

  final io.Socket _socket;

  @override
  bool get connected => _socket.connected;

  @override
  void connect() => _socket.connect();

  @override
  void onConnect(void Function(dynamic data) handler) =>
      _socket.onConnect(handler);

  @override
  void onDisconnect(void Function(dynamic data) handler) =>
      _socket.onDisconnect(handler);

  @override
  void onConnectError(void Function(dynamic data) handler) =>
      _socket.onConnectError(handler);

  @override
  void on(String event, void Function(dynamic data) handler) =>
      _socket.on(event, handler);

  @override
  void off(String event) => _socket.off(event);

  @override
  void emit(String event, Map<String, dynamic> data) => _socket.emit(event, data);

  @override
  void emitWithAck(
    String event,
    Map<String, dynamic> data, {
    void Function(dynamic response)? ack,
  }) => _socket.emitWithAck(event, data, ack: ack);

  @override
  void dispose() => _socket.dispose();
}

typedef ParentRealtimeSocketFactory =
    ParentRealtimeSocket Function({required String baseUrl, required String token});

/// Cliente realtime do app do pai: conecta no gateway Socket.IO do backend,
/// assina a room da rota (`subscribe.route`) e repassa as posições da van
/// (`telemetry.location.updated`) assim que chegam — sem polling HTTP.
///
/// Também repassa `route.status.updated` e `boarding.status.updated`: sem
/// esses eventos a tela só descobria início/fim de rota e embarques no
/// polling de fallback (que fica em standby com o socket vivo).
///
/// O socket_io_client faz reconexão automática; a cada `connect` (primeira
/// ou reconexão) a assinatura da rota é refeita. A UI trata
/// [ParentRealtimeStatus.connected] como "ao vivo"; nos demais estados o
/// polling HTTP de 15s assume como fallback silencioso (sem mensagem de erro
/// para o usuário — ver `ParentRealtimeController` e `LiveTrackingOverlay`).
class ParentRealtimeService {
  ParentRealtimeService({
    required String baseUrl,
    ParentRealtimeSocketFactory? socketFactory,
  }) : _baseUrl = baseUrl,
       _socketFactory = socketFactory ?? _defaultSocketFactory;

  static const eventLocationUpdated = 'telemetry.location.updated';
  static const eventRouteStatusUpdated = 'route.status.updated';
  static const eventBoardingStatusUpdated = 'boarding.status.updated';
  static const _eventSubscribeRoute = 'subscribe.route';
  static const _eventUnsubscribeRoute = 'unsubscribe.route';

  final String _baseUrl;
  final ParentRealtimeSocketFactory _socketFactory;

  ParentRealtimeSocket? _socket;
  String? _token;
  int? _routeId;
  ParentRealtimeStatus _status = ParentRealtimeStatus.disconnected;

  final _statusController = StreamController<ParentRealtimeStatus>.broadcast();
  final _locationController = StreamController<ParentVanLocation>.broadcast();
  final _routeStatusController =
      StreamController<ParentRouteStatusEvent>.broadcast();
  final _boardingStatusController =
      StreamController<ParentBoardingStatusEvent>.broadcast();

  Stream<ParentRealtimeStatus> get statusChanges => _statusController.stream;
  Stream<ParentVanLocation> get locations => _locationController.stream;
  Stream<ParentRouteStatusEvent> get routeStatuses =>
      _routeStatusController.stream;
  Stream<ParentBoardingStatusEvent> get boardingStatuses =>
      _boardingStatusController.stream;
  ParentRealtimeStatus get status => _status;
  int? get watchedRouteId => _routeId;

  static ParentRealtimeSocket _defaultSocketFactory({
    required String baseUrl,
    required String token,
  }) => _SocketIoSocket(baseUrl: baseUrl, token: token);

  /// Assina a rota [routeId]. Cria o socket na primeira chamada (ou quando o
  /// token muda) e reutiliza a conexão entre trocas de rota.
  void watchRoute({required int routeId, required String token}) {
    if (token.isEmpty) return;

    if (_socket == null || _token != token) {
      _teardownSocket();
      _token = token;
      _setStatus(ParentRealtimeStatus.connecting);
      final socket = _socketFactory(baseUrl: _baseUrl, token: token);
      _socket = socket;
      _bindSocket(socket);
      socket.connect();
    }

    final previousRouteId = _routeId;
    _routeId = routeId;
    if (previousRouteId != null && previousRouteId != routeId) {
      _socket?.emit(_eventUnsubscribeRoute, <String, dynamic>{
        'routeId': previousRouteId,
      });
    }
    _subscribeWatchedRoute();
  }

  /// Sai da room e encerra o socket (rota finalizada ou tela fechada).
  void unwatch() {
    final routeId = _routeId;
    _routeId = null;
    final socket = _socket;
    if (routeId != null && socket != null && socket.connected) {
      socket.emit(_eventUnsubscribeRoute, <String, dynamic>{'routeId': routeId});
    }
    _teardownSocket();
    _token = null;
    _setStatus(ParentRealtimeStatus.disconnected);
  }

  /// Força uma nova conexão mantendo a rota assinada — ação "tentar de novo"
  /// da UI quando a reconexão automática não vingou. O socket antigo é
  /// descartado e um novo é aberto com o mesmo token; a assinatura da rota é
  /// refeita no `connect` (handler em [_bindSocket]).
  void reconnect() {
    final token = _token;
    if (token == null || token.isEmpty || _routeId == null) return;
    _teardownSocket();
    _setStatus(ParentRealtimeStatus.connecting);
    final socket = _socketFactory(baseUrl: _baseUrl, token: token);
    _socket = socket;
    _bindSocket(socket);
    socket.connect();
    _subscribeWatchedRoute();
  }

  void dispose() {
    unwatch();
    unawaited(_statusController.close());
    unawaited(_locationController.close());
    unawaited(_routeStatusController.close());
    unawaited(_boardingStatusController.close());
  }

  void _bindSocket(ParentRealtimeSocket socket) {
    socket.onConnect((_) {
      _setStatus(ParentRealtimeStatus.connected);
      // Primeira conexão e reconexões: a assinatura precisa ser refeita (a
      // room é por conexão no gateway).
      _subscribeWatchedRoute();
    });
    socket.onDisconnect((_) {
      _setStatus(ParentRealtimeStatus.disconnected);
    });
    socket.onConnectError((error) {
      debugPrint('[ParentRealtimeService] connect_error: $error');
      _setStatus(ParentRealtimeStatus.disconnected);
    });
    socket.on(eventLocationUpdated, _handleLocationUpdated);
    socket.on(eventRouteStatusUpdated, _handleRouteStatusUpdated);
    socket.on(eventBoardingStatusUpdated, _handleBoardingStatusUpdated);
  }

  void _subscribeWatchedRoute() {
    final routeId = _routeId;
    final socket = _socket;
    if (routeId == null || socket == null || !socket.connected) return;
    socket.emitWithAck(_eventSubscribeRoute, <String, dynamic>{
      'routeId': routeId,
    }, ack: (response) {
      if (response is Map && response['success'] == false) {
        debugPrint(
          '[ParentRealtimeService] subscribe.route negado: '
          '${response['error']}',
        );
      }
    });
  }

  void _handleLocationUpdated(dynamic payload) {
    if (payload is! Map) return;
    final map = Map<String, dynamic>.from(payload);

    final routeId = (map['routeId'] as num?)?.toInt();
    final watched = _routeId;
    if (watched != null && routeId != null && routeId != watched) return;

    final lat = (map['latitude'] as num?)?.toDouble();
    final lng = (map['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return;

    final rawTimestamp = map['timestamp'];
    _locationController.add(
      ParentVanLocation(
        latitude: lat,
        longitude: lng,
        routeId: routeId,
        at: rawTimestamp == null
            ? null
            : DateTime.tryParse(rawTimestamp.toString()),
        speedKmh: (map['speed'] as num?)?.toDouble(),
        heading: (map['heading'] as num?)?.toDouble(),
      ),
    );
  }

  void _handleRouteStatusUpdated(dynamic payload) {
    if (payload is! Map) return;
    final map = Map<String, dynamic>.from(payload);

    final routeId = (map['routeId'] as num?)?.toInt();
    final watched = _routeId;
    if (watched != null && routeId != null && routeId != watched) return;

    _routeStatusController.add(
      ParentRouteStatusEvent(
        routeId: routeId,
        status: map['status']?.toString(),
      ),
    );
  }

  void _handleBoardingStatusUpdated(dynamic payload) {
    if (payload is! Map) return;
    final map = Map<String, dynamic>.from(payload);

    final routeId = (map['routeId'] as num?)?.toInt();
    final watched = _routeId;
    if (watched != null && routeId != null && routeId != watched) return;

    _boardingStatusController.add(
      ParentBoardingStatusEvent(
        routeId: routeId,
        childId: (map['childId'] as num?)?.toInt(),
        status: map['status']?.toString(),
      ),
    );
  }

  void _teardownSocket() {
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      socket.off(eventLocationUpdated);
      socket.off(eventRouteStatusUpdated);
      socket.off(eventBoardingStatusUpdated);
      socket.dispose();
    }
  }

  void _setStatus(ParentRealtimeStatus status) {
    if (_status == status) return;
    _status = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}
