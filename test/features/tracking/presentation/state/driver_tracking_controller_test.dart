import 'dart:async';

import 'package:app_faixa_amarela/core/network/network_providers.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_session.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_user.dart';
import 'package:app_faixa_amarela/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:app_faixa_amarela/features/tracking/presentation/state/driver_tracking_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
        // O preview só é aplicado com rota ativa.
        ctrl.state = const DriverTrackingState(routeActive: true);
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

  group('DriverTrackingController encerramento da rota', () {
    test('stopRouteTracking limpa posição e visual da rota', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ctrl = container.read(driverTrackingControllerProvider.notifier);
      ctrl.state = DriverTrackingState(
        routeActive: true,
        routeId: 42,
        routeManifestId: 'route.42',
        vanId: 7,
        lastLatitude: -25.5,
        lastLongitude: -54.5,
        lastSpeedKmh: 30,
        lastHeading: 90,
        routePolyline: const [
          (lat: -25.0, lng: -54.0),
          (lat: -25.1, lng: -54.1),
        ],
        routeRemainingStops: [
          _stop(childId: 10, type: 'pickup', status: 'pending', sequence: 1),
        ],
      );

      await ctrl.stopRouteTracking(silent: true);

      expect(ctrl.state.routeActive, isFalse);
      expect(ctrl.state.lastLatitude, isNull);
      expect(ctrl.state.lastLongitude, isNull);
      expect(ctrl.state.lastSpeedKmh, isNull);
      expect(ctrl.state.lastHeading, isNull);
      expect(ctrl.state.routePolyline, isEmpty);
      expect(ctrl.state.routeRemainingStops, isEmpty);
    });

    test('primeRoutePreview ignora chamada com rota inativa', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ctrl = container.read(driverTrackingControllerProvider.notifier);
      // Estado default: routeActive false (ex.: encerramento no meio do start).
      ctrl.primeRoutePreview(
        remainingStops: [
          {
            'childId': 10,
            'type': 'pickup',
            'status': 'pending',
            'sequence': 1,
            'latitude': -25.0,
            'longitude': -54.0,
            'name': 'Aluno A',
          },
        ],
      );

      expect(ctrl.state.routeRemainingStops, isEmpty);
      expect(ctrl.state.routePolyline, isEmpty);
    });

    test('recalculate em voo não repovoa a rota depois do stop', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final adapter = _HeldRecalculateAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      addTearDown(dio.close);
      final container = ProviderContainer(
        overrides: [dioProvider.overrideWithValue(dio)],
      );
      addTearDown(container.dispose);

      final ctrl = container.read(driverTrackingControllerProvider.notifier);
      ctrl.state = const DriverTrackingState(
        routeActive: true,
        routeId: 42,
        routeManifestId: 'route.42',
        vanId: 7,
        lastLatitude: -25.5,
        lastLongitude: -54.5,
      );
      ctrl.syncSession(
        AuthSession(
          accessToken: 'token-abc',
          tokenType: 'Bearer',
          user: AuthUser(
            id: 1,
            name: 'Motorista',
            email: 'motorista@email.com',
            roles: const ['driver'],
          ),
        ),
      );

      final refreshFuture = ctrl.refreshRoutePreviewNow();
      await pumpEventQueue();
      expect(adapter.calls, 1);

      // Encerra a rota com o recálculo em voo (a janela da race).
      await ctrl.stopRouteTracking(silent: true);
      expect(ctrl.state.routeActive, isFalse);

      adapter.release();
      await refreshFuture;

      // A resposta tardia não pode repovoar paradas/polyline — era o que
      // virava o traçado reto azul no mapa depois do encerramento.
      expect(ctrl.state.routePolyline, isEmpty);
      expect(ctrl.state.routeRemainingStops, isEmpty);
    });
  });
}

/// Adapter que segura a resposta do /recalculate até [release] — reproduz a
/// janela em que a rota é encerrada com o recálculo em voo.
class _HeldRecalculateAdapter implements HttpClientAdapter {
  final Completer<void> _gate = Completer<void>();
  int calls = 0;

  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    await _gate.future;
    return ResponseBody.fromString(
      '{"distanceMeters":100,"durationSeconds":60,'
      '"remainingStops":[{"childId":10,"type":"pickup","status":"pending",'
      '"sequence":1,"latitude":-25.1,"longitude":-54.1,"name":"Aluno A"}],'
      '"geometry":null}',
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
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
