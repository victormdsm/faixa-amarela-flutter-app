import 'package:app_faixa_amarela/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:app_faixa_amarela/features/tracking/presentation/state/driver_tracking_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('DriverTrackingController stop-type compatibility', () {
    test('markClientBoardedLocal updates generic pickup stop', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ctrl = container.read(driverTrackingControllerProvider.notifier);
      ctrl.state = DriverTrackingState(
        routeActive: true,
        routePlannedStops: [
          _stop(childId: 10, type: 'pickup', status: 'pending', sequence: 1),
        ],
        routeRemainingStops: [
          _stop(childId: 10, type: 'pickup', status: 'pending', sequence: 1),
        ],
      );

      ctrl.markClientBoardedLocal(10);

      expect(
        ctrl.state.routePlannedStops.first.status,
        'picked_up',
      );
      expect(ctrl.state.routeRemainingStops, isEmpty);
    });

    test('markClientBoardedLocal updates pickup_home stop', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ctrl = container.read(driverTrackingControllerProvider.notifier);
      ctrl.state = DriverTrackingState(
        routeActive: true,
        routePlannedStops: [
          _stop(childId: 10, type: 'pickup_home', status: 'pending', sequence: 1),
        ],
        routeRemainingStops: [
          _stop(childId: 10, type: 'pickup_home', status: 'pending', sequence: 1),
        ],
      );

      ctrl.markClientBoardedLocal(10);

      expect(
        ctrl.state.routePlannedStops.first.status,
        'picked_up',
      );
    });

    test('markClientDisembarkedLocal updates generic dropoff stop', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ctrl = container.read(driverTrackingControllerProvider.notifier);
      ctrl.state = DriverTrackingState(
        routeActive: true,
        routePlannedStops: [
          _stop(childId: 10, type: 'dropoff', status: 'pending', sequence: 1),
        ],
        routeRemainingStops: [
          _stop(childId: 10, type: 'dropoff', status: 'pending', sequence: 1),
        ],
      );

      ctrl.markClientDisembarkedLocal(10);

      expect(
        ctrl.state.routePlannedStops.first.status,
        'delivered',
      );
      expect(ctrl.state.routeRemainingStops, isEmpty);
    });

    test('markClientDisembarkedLocal updates dropoff_school stop', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ctrl = container.read(driverTrackingControllerProvider.notifier);
      ctrl.state = DriverTrackingState(
        routeActive: true,
        routePlannedStops: [
          _stop(childId: 10, type: 'dropoff_school', status: 'pending', sequence: 1),
        ],
        routeRemainingStops: [
          _stop(childId: 10, type: 'dropoff_school', status: 'pending', sequence: 1),
        ],
      );

      ctrl.markClientDisembarkedLocal(10);

      expect(
        ctrl.state.routePlannedStops.first.status,
        'delivered',
      );
    });

    group('backend vocabulary (single pickup stop per child)', () {
      test('disembark targets boarded pickup stop (bug: tap morria aqui)', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final ctrl = container.read(driverTrackingControllerProvider.notifier);
        ctrl.state = DriverTrackingState(
          routeActive: true,
          routePlannedStops: [
            _stop(childId: 10, type: 'pickup', status: 'picked_up', sequence: 1),
          ],
          routeRemainingStops: const [],
        );

        ctrl.markClientDisembarkedLocal(10);

        expect(ctrl.state.routePlannedStops.first.status, 'delivered');
        expect(ctrl.state.routeRemainingStops, isEmpty);
      });

      test('primeRoutePreview normaliza boarded/disembarked do backend', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final ctrl = container.read(driverTrackingControllerProvider.notifier);
        ctrl.primeRoutePreview(
          remainingStops: [
            {
              'childId': 10,
              'type': 'pickup',
              'status': 'boarded',
              'sequence': 1,
              'latitude': -25.0,
              'longitude': -54.0,
              'name': 'Aluno A',
            },
            {
              'childId': 11,
              'type': 'pickup',
              'status': 'disembarked',
              'sequence': 2,
              'latitude': -25.1,
              'longitude': -54.1,
              'name': 'Aluno B',
            },
          ],
        );

        final planned = ctrl.state.routePlannedStops;
        expect(planned[0].status, 'picked_up');
        expect(planned[1].status, 'delivered');
      });

      test('rollback otimista reverte picked_up para pending', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final ctrl = container.read(driverTrackingControllerProvider.notifier);
        ctrl.state = DriverTrackingState(
          routeActive: true,
          routePlannedStops: [
            _stop(childId: 10, type: 'pickup', status: 'picked_up', sequence: 1),
          ],
          routeRemainingStops: const [],
        );

        ctrl.updateClientStopStatusLocal(10, 'pending');

        expect(ctrl.state.routePlannedStops.first.status, 'pending');
        expect(ctrl.state.routeRemainingStops, hasLength(1));
      });

      test('rollback do desembarque reverte delivered para picked_up', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final ctrl = container.read(driverTrackingControllerProvider.notifier);
        ctrl.state = DriverTrackingState(
          routeActive: true,
          routePlannedStops: [
            _stop(childId: 10, type: 'pickup', status: 'delivered', sequence: 1),
          ],
          routeRemainingStops: const [],
        );

        ctrl.updateClientStopStatusLocal(10, 'picked_up');

        expect(ctrl.state.routePlannedStops.first.status, 'picked_up');
      });

      test('stops absent/removed não voltam como restantes', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final ctrl = container.read(driverTrackingControllerProvider.notifier);
        ctrl.state = DriverTrackingState(
          routeActive: true,
          routePlannedStops: [
            _stop(childId: 10, type: 'pickup', status: 'absent', sequence: 1),
            _stop(childId: 11, type: 'pickup', status: 'pending', sequence: 2),
          ],
          routeRemainingStops: const [],
        );

        // Embarcar o ausente não pode alterar nada (status terminal).
        ctrl.markClientBoardedLocal(10);
        expect(ctrl.state.routePlannedStops.first.status, 'absent');

        ctrl.markClientBoardedLocal(11);
        expect(ctrl.state.routePlannedStops.last.status, 'picked_up');
        expect(ctrl.state.routeRemainingStops, isEmpty);
      });
    });
  });
}

DriverTrackingStopPoint _stop({
  required int childId,
  required String type,
  required String status,
  required int sequence,
  double lat = -25.0,
  double lng = -54.0,
  String name = 'Aluno',
}) {
  return (
    id: null,
    clientId: null,
    childId: childId,
    type: type,
    status: status,
    sequence: sequence,
    lat: lat,
    lng: lng,
    name: name,
  );
}
