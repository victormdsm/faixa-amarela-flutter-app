import 'package:app_faixa_amarela/features/parent_portal/data/parent_realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ParentRealtimeService', () {
    late _FakeParentRealtimeSocket socket;
    late ParentRealtimeService service;

    setUp(() {
      service = ParentRealtimeService(
        baseUrl: 'http://localhost:3000',
        socketFactory: ({required baseUrl, required token}) {
          expect(baseUrl, 'http://localhost:3000');
          expect(token, 'token-abc');
          return socket = _FakeParentRealtimeSocket();
        },
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('watchRoute conecta e assina a rota após o connect', () async {
      final statusExpectation = expectLater(
        service.statusChanges,
        emitsInOrder([
          ParentRealtimeStatus.connecting,
          ParentRealtimeStatus.connected,
        ]),
      );

      service.watchRoute(routeId: 7, token: 'token-abc');
      expect(service.status, ParentRealtimeStatus.connecting);
      // Antes do connect não há assinatura (a room é por conexão).
      expect(socket.ackEmissions, isEmpty);

      socket.simulateConnect();
      await statusExpectation;
      expect(service.status, ParentRealtimeStatus.connected);
      expect(socket.ackEmissions.single.$1, 'subscribe.route');
      expect(socket.ackEmissions.single.$2, {'routeId': 7});
    });

    test('repassa telemetry.location.updated da rota assinada na hora', () async {
      service.watchRoute(routeId: 7, token: 'token-abc');
      socket.simulateConnect();

      final locationExpectation = expectLater(
        service.locations,
        emits(
          isA<ParentVanLocation>()
              .having((l) => l.latitude, 'latitude', -25.5163)
              .having((l) => l.longitude, 'longitude', -54.5854)
              .having((l) => l.routeId, 'routeId', 7)
              .having((l) => l.speedKmh, 'speedKmh', 32.5)
              .having((l) => l.heading, 'heading', 90)
              .having(
                (l) => l.at,
                'at',
                DateTime.parse('2026-07-30T18:00:00.000Z'),
              ),
        ),
      );

      socket.simulateLocation({
        'routeId': 7,
        'latitude': -25.5163,
        'longitude': -54.5854,
        'speed': 32.5,
        'heading': 90,
        'timestamp': '2026-07-30T18:00:00.000Z',
      });

      await locationExpectation;
    });

    test('ignora posição de outra rota e payload sem lat/lng', () async {
      service.watchRoute(routeId: 7, token: 'token-abc');
      socket.simulateConnect();

      final received = <ParentVanLocation>[];
      final sub = service.locations.listen(received.add);

      socket.simulateLocation({'routeId': 99, 'latitude': -25.0, 'longitude': -54.0});
      socket.simulateLocation({'routeId': 7, 'speed': 10});
      // Entrega do broadcast é assíncrona: drena a fila antes de afirmar.
      await pumpEventQueue();
      expect(received, isEmpty);
      await sub.cancel();
    });

    test('troca de rota sai da room anterior e assina a nova', () {
      service.watchRoute(routeId: 7, token: 'token-abc');
      socket.simulateConnect();

      service.watchRoute(routeId: 8, token: 'token-abc');

      expect(
        socket.emissions.any(
          (e) => e.$1 == 'unsubscribe.route' && e.$2['routeId'] == 7,
        ),
        isTrue,
      );
      expect(socket.ackEmissions.last.$2, {'routeId': 8});
    });

    test('reconexão refaz a assinatura da rota', () {
      service.watchRoute(routeId: 7, token: 'token-abc');
      socket.simulateConnect();
      socket.simulateDisconnect();
      expect(service.status, ParentRealtimeStatus.disconnected);

      socket.simulateConnect();
      expect(service.status, ParentRealtimeStatus.connected);
      expect(socket.ackEmissions, hasLength(2));
      expect(socket.ackEmissions.last.$2, {'routeId': 7});
    });

    test('unwatch sai da room, encerra o socket e desconecta', () async {
      service.watchRoute(routeId: 7, token: 'token-abc');
      socket.simulateConnect();

      service.unwatch();

      expect(
        socket.emissions.any(
          (e) => e.$1 == 'unsubscribe.route' && e.$2['routeId'] == 7,
        ),
        isTrue,
      );
      expect(socket.disposed, isTrue);
      expect(service.status, ParentRealtimeStatus.disconnected);
      expect(service.watchedRouteId, isNull);
    });

    test('watchRoute com token vazio não conecta', () {
      service.watchRoute(routeId: 7, token: '');
      expect(service.status, ParentRealtimeStatus.disconnected);
      expect(service.watchedRouteId, isNull);
    });
  });
}

/// Socket fake: disparo manual de connect/disconnect/eventos, sem rede.
class _FakeParentRealtimeSocket implements ParentRealtimeSocket {
  final handlers = <String, List<void Function(dynamic)>>{};
  final emissions = <(String, Map<String, dynamic>)>[];
  final ackEmissions =
      <(String, Map<String, dynamic>, void Function(dynamic)?)>[];
  void Function(dynamic)? connectHandler;
  void Function(dynamic)? disconnectHandler;
  void Function(dynamic)? connectErrorHandler;
  bool disposed = false;
  bool _connected = false;

  @override
  bool get connected => _connected;

  @override
  void connect() {}

  @override
  void onConnect(void Function(dynamic data) handler) =>
      connectHandler = handler;

  @override
  void onDisconnect(void Function(dynamic data) handler) =>
      disconnectHandler = handler;

  @override
  void onConnectError(void Function(dynamic data) handler) =>
      connectErrorHandler = handler;

  @override
  void on(String event, void Function(dynamic data) handler) =>
      handlers.putIfAbsent(event, () => []).add(handler);

  @override
  void off(String event) => handlers.remove(event);

  @override
  void emit(String event, Map<String, dynamic> data) =>
      emissions.add((event, data));

  @override
  void emitWithAck(
    String event,
    Map<String, dynamic> data, {
    void Function(dynamic response)? ack,
  }) =>
      ackEmissions.add((event, data, ack));

  @override
  void dispose() {
    disposed = true;
    _connected = false;
  }

  void simulateConnect() {
    _connected = true;
    connectHandler?.call(null);
  }

  void simulateDisconnect() {
    _connected = false;
    disconnectHandler?.call(null);
  }

  void simulateLocation(Map<String, dynamic> payload) {
    for (final handler
        in handlers[ParentRealtimeService.eventLocationUpdated] ??
            const <void Function(dynamic)>[]) {
      handler(payload);
    }
  }
}
