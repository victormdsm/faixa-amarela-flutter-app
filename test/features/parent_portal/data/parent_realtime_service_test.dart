import 'package:app_faixa_amarela/features/parent_portal/data/parent_realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_parent_realtime_socket.dart';

late List<FakeParentRealtimeSocket> sockets;
late ParentRealtimeService service;

/// Último socket criado pela factory (reconnect cria um novo).
FakeParentRealtimeSocket get socket => sockets.last;

void main() {
  group('ParentRealtimeService', () {
    setUp(() {
      sockets = [];
      service = ParentRealtimeService(
        baseUrl: 'http://localhost:3000',
        socketFactory: ({required baseUrl, required token}) {
          expect(baseUrl, 'http://localhost:3000');
          expect(token, 'token-abc');
          final created = FakeParentRealtimeSocket();
          sockets.add(created);
          return created;
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

    test('repassa route.status.updated e boarding.status.updated da rota assinada', () async {
      service.watchRoute(routeId: 7, token: 'token-abc');
      socket.simulateConnect();

      final routeStatusExpectation = expectLater(
        service.routeStatuses,
        emits(
          isA<ParentRouteStatusEvent>()
              .having((e) => e.routeId, 'routeId', 7)
              .having((e) => e.status, 'status', 'finished'),
        ),
      );
      final boardingExpectation = expectLater(
        service.boardingStatuses,
        emits(
          isA<ParentBoardingStatusEvent>()
              .having((e) => e.routeId, 'routeId', 7)
              .having((e) => e.childId, 'childId', 10)
              .having((e) => e.status, 'status', 'boarded'),
        ),
      );

      socket.simulateRouteStatus({'routeId': 7, 'status': 'finished'});
      socket.simulateBoardingStatus({
        'routeId': 7,
        'childId': 10,
        'status': 'boarded',
      });

      await routeStatusExpectation;
      await boardingExpectation;
    });

    test('ignora status de outra rota', () async {
      service.watchRoute(routeId: 7, token: 'token-abc');
      socket.simulateConnect();

      final routeStatuses = <ParentRouteStatusEvent>[];
      final boardingStatuses = <ParentBoardingStatusEvent>[];
      final subRoute = service.routeStatuses.listen(routeStatuses.add);
      final subBoarding = service.boardingStatuses.listen(
        boardingStatuses.add,
      );

      socket.simulateRouteStatus({'routeId': 99, 'status': 'finished'});
      socket.simulateBoardingStatus({
        'routeId': 99,
        'childId': 10,
        'status': 'boarded',
      });
      // Entrega do broadcast é assíncrona: drena a fila antes de afirmar.
      await pumpEventQueue();
      expect(routeStatuses, isEmpty);
      expect(boardingStatuses, isEmpty);
      await subRoute.cancel();
      await subBoarding.cancel();
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

    test('reconnect descarta o socket travado e reabre mantendo a rota', () {
      service.watchRoute(routeId: 7, token: 'token-abc');
      socket.simulateConnect();
      final first = socket;

      service.reconnect();

      expect(first.disposed, isTrue);
      expect(service.status, ParentRealtimeStatus.connecting);
      expect(sockets, hasLength(2));

      final next = sockets.last;
      next.simulateConnect();
      expect(service.status, ParentRealtimeStatus.connected);
      // Assinatura refeita no novo socket (a room é por conexão).
      expect(next.ackEmissions.single.$1, 'subscribe.route');
      expect(next.ackEmissions.single.$2, {'routeId': 7});
    });

    test('reconnect sem rota assinada não faz nada', () {
      service.reconnect();
      expect(sockets, isEmpty);
      expect(service.status, ParentRealtimeStatus.disconnected);
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
