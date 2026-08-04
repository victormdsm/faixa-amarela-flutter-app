import 'package:app_faixa_amarela/features/driver_portal/presentation/widgets/route_passenger_tile.dart';
import 'package:app_faixa_amarela/features/driver_portal/presentation/widgets/route_passengers_list.dart';
import 'package:app_faixa_amarela/features/tracking/presentation/state/driver_tracking_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildStudentRouteCards', () {
    test('groups NestJS stops with generic pickup type', () {
      final tracking = DriverTrackingState(
        routeActive: true,
        routePlannedStops: [
          _stop(childId: 10, type: 'pickup', status: 'pending', name: 'Ana Silva', sequence: 1),
          _stop(childId: 11, type: 'pickup', status: 'pending', name: 'Bruno Souza', sequence: 2),
        ],
        routeRemainingStops: [
          _stop(childId: 10, type: 'pickup', status: 'pending', name: 'Ana Silva', sequence: 1),
        ],
      );

      final cards = buildStudentRouteCards(tracking);

      expect(cards, hasLength(2));
      expect(cards.first.childId, 10);
      expect(cards.first.name, 'Ana Silva');
      expect(cards.first.status, StopStatus.onTheWay);
      expect(cards.first.pickupLabel, isNotNull);
      expect(cards[1].status, StopStatus.pending);
    });

    test('groups Laravel stops with pickup_home and dropoff_school types', () {
      final tracking = DriverTrackingState(
        routeActive: true,
        routePlannedStops: [
          _stop(childId: 10, type: 'pickup_home', status: 'pending', name: 'Ana Silva', sequence: 1),
          _stop(childId: 10, type: 'dropoff_school', status: 'pending', name: 'Escola Primavera', sequence: 3),
          _stop(childId: 11, type: 'pickup_home', status: 'pending', name: 'Bruno Souza', sequence: 2),
        ],
        routeRemainingStops: [
          _stop(childId: 10, type: 'pickup_home', status: 'pending', name: 'Ana Silva', sequence: 1),
        ],
      );

      final cards = buildStudentRouteCards(tracking);

      expect(cards, hasLength(2));
      final ana = cards.firstWhere((c) => c.childId == 10);
      expect(ana.pickupLabel, isNotNull);
      expect(ana.dropoffLabel, isNotNull);
      expect(ana.status, StopStatus.onTheWay);
    });

    test('recognizes picked_up and delivered statuses', () {
      final tracking = DriverTrackingState(
        routeActive: true,
        routePlannedStops: [
          _stop(childId: 10, type: 'pickup', status: 'picked_up', name: 'Ana Silva', sequence: 1),
          _stop(childId: 11, type: 'pickup', status: 'delivered', name: 'Bruno Souza', sequence: 2),
        ],
        routeRemainingStops: const [],
      );

      final cards = buildStudentRouteCards(tracking);

      final ana = cards.firstWhere((c) => c.childId == 10);
      final bruno = cards.firstWhere((c) => c.childId == 11);
      expect(ana.status, StopStatus.boarded);
      expect(bruno.status, StopStatus.droppedOff);
    });

    test('ignores stops without childId', () {
      final tracking = DriverTrackingState(
        routeActive: true,
        routePlannedStops: [
          _stop(childId: null, type: 'dropoff_school', status: 'pending', name: 'Escola', sequence: 3),
          _stop(childId: 10, type: 'pickup', status: 'pending', name: 'Ana Silva', sequence: 1),
        ],
        routeRemainingStops: [
          _stop(childId: 10, type: 'pickup', status: 'pending', name: 'Ana Silva', sequence: 1),
        ],
      );

      final cards = buildStudentRouteCards(tracking);

      expect(cards, hasLength(1));
      expect(cards.first.childId, 10);
    });

    test('recognizes backend boarded/disembarked statuses', () {
      final tracking = DriverTrackingState(
        routeActive: true,
        routePlannedStops: [
          _stop(childId: 10, type: 'pickup', status: 'boarded', name: 'Ana Silva', sequence: 1),
          _stop(childId: 11, type: 'pickup', status: 'disembarked', name: 'Bruno Souza', sequence: 2),
          _stop(childId: 12, type: 'pickup', status: 'pending', name: 'Carla Lima', sequence: 3),
        ],
        routeRemainingStops: const [],
      );

      final cards = buildStudentRouteCards(tracking);

      expect(cards, hasLength(3));
      expect(cards[0].status, StopStatus.boarded);
      expect(cards[1].status, StopStatus.droppedOff);
      expect(cards[2].status, StopStatus.pending);
    });

    test('absent/removed complete the card (no pending dead actions)', () {
      final tracking = DriverTrackingState(
        routeActive: true,
        routePlannedStops: [
          _stop(childId: 10, type: 'pickup', status: 'absent', name: 'Ana Silva', sequence: 1),
          _stop(childId: 11, type: 'pickup', status: 'removed', name: 'Bruno Souza', sequence: 2),
        ],
        routeRemainingStops: const [],
      );

      final cards = buildStudentRouteCards(tracking);

      expect(cards[0].status, StopStatus.droppedOff);
      expect(cards[1].status, StopStatus.droppedOff);
    });

    test('all delivered (backend vocab) enables auto-finish condition', () {
      final tracking = DriverTrackingState(
        routeActive: true,
        routePlannedStops: [
          _stop(childId: 10, type: 'pickup', status: 'disembarked', name: 'Ana Silva', sequence: 1),
          _stop(childId: 11, type: 'pickup', status: 'delivered', name: 'Bruno Souza', sequence: 2),
        ],
        routeRemainingStops: const [],
      );

      final cards = buildStudentRouteCards(tracking);

      expect(
        cards.isNotEmpty && cards.every((s) => s.status == StopStatus.droppedOff),
        isTrue,
      );
    });
  });

  group('RoutePassengerTile', () {
    testWidgets('renders student name and action buttons', (tester) async {
      const student = StudentRouteCard(
        clientId: 1,
        childId: 10,
        name: 'Ana Silva',
        sequence: 1,
        status: StopStatus.pending,
        pickupLabel: 'Rua das Flores, 100',
        nextAction: 'Coletar',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePassengerTile(
              student: student,
              submitting: false,
              routeActive: true,
              onBoard: () {},
              onDisembark: () {},
              onNotifyArrived: () {},
              onNotifyDelayed: () {},
              onRemove: () {},
            ),
          ),
        ),
      );

      expect(find.text('Ana Silva'), findsOneWidget);
      expect(find.text('Embarcou'), findsOneWidget);
      expect(find.text('Desembarcou'), findsOneWidget);
      expect(find.text('Embarque: Rua das Flores, 100'), findsOneWidget);
    });

    testWidgets('expands to show notify and remove actions', (tester) async {
      const student = StudentRouteCard(
        clientId: 1,
        childId: 10,
        name: 'Ana Silva',
        sequence: 1,
        status: StopStatus.pending,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePassengerTile(
              student: student,
              submitting: false,
              routeActive: true,
              onBoard: () {},
              onNotifyArrived: () {},
              onNotifyDelayed: () {},
              onRemove: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ana Silva'));
      await tester.pumpAndSettle();

      expect(find.text('Notificar responsável'), findsOneWidget);
      expect(find.text('Cheguei'), findsOneWidget);
      expect(find.text('Vou atrasar'), findsOneWidget);
      expect(find.text('Remover da rota'), findsOneWidget);
    });
  });
}

DriverTrackingStopPoint _stop({
  required int? childId,
  required String type,
  required String status,
  required String name,
  required int sequence,
  double lat = -25.0,
  double lng = -54.0,
  int? clientId,
  String? id,
}) {
  return (
    id: id,
    clientId: clientId,
    childId: childId,
    type: type,
    status: status,
    sequence: sequence,
    lat: lat,
    lng: lng,
    name: name,
  );
}
