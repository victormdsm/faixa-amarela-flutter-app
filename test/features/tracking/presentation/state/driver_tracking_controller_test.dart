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
