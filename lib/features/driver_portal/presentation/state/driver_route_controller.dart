import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/route_manifest.dart';
import '../../../../domain/models/route_manifest.dart' as models;
import '../providers/driver_portal_providers.dart';

class DriverRouteController extends AsyncNotifier<RouteManifest?> {
  Future<RouteManifest?> _load() async {
    final repo = ref.read(driverRoutesRepositoryProvider);
    return repo.getActiveRoute();
  }

  @override
  Future<RouteManifest?> build() async => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> markBoarded(int childId) async {
    final current = state.asData?.value;
    if (current == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(driverRoutesRepositoryProvider);
      final updatedStop = await repo.markBoarding(current.id, childId);
      return _mergeStop(current, updatedStop);
    });
  }

  Future<void> markDisembarked(int childId) async {
    final current = state.asData?.value;
    if (current == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(driverRoutesRepositoryProvider);
      final updatedStop = await repo.markDisembarking(current.id, childId);
      return _mergeStop(current, updatedStop);
    });
  }

  Future<void> markAbsent(int childId) async {
    final current = state.asData?.value;
    if (current == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(driverRoutesRepositoryProvider);
      final updatedStop = await repo.markAbsent(current.id, childId);
      return _mergeStop(current, updatedStop);
    });
  }

  Future<void> removeStudent(int childId) async {
    final current = state.asData?.value;
    if (current == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(driverRoutesRepositoryProvider);
      await repo.removeStudent(current.id, childId);
      // Recarrega a rota: a remoção é irreversível no dia e o backend é a
      // fonte de verdade sobre o status final da parada.
      final refreshed = await repo.getActiveRoute();
      return refreshed ?? current;
    });
  }

  Future<void> bulkDisembarkAtSchool(int schoolId) async {
    final current = state.asData?.value;
    if (current == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(driverRoutesRepositoryProvider);
      final updatedStops = await repo.bulkDisembarkAtSchool(
        current.id,
        schoolId,
      );
      return _mergeStops(current, updatedStops);
    });
  }

  Future<void> finishRoute() async {
    final current = state.asData?.value;
    if (current == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(driverRoutesRepositoryProvider);
      await repo.finishRoute(current.id);
      return null;
    });
    // APP-18: rota finalizada — dashboard e lista de rotas precisam refletir.
    if (!state.hasError) {
      ref.invalidate(driverDashboardControllerProvider);
      ref.invalidate(driverRoutesProvider);
    }
  }

  RouteManifest _mergeStop(RouteManifest manifest, models.RouteStop updated) {
    return RouteManifest(
      id: manifest.id,
      driverId: manifest.driverId,
      vanId: manifest.vanId,
      startedAt: manifest.startedAt,
      finishedAt: manifest.finishedAt,
      status: manifest.status,
      stops: manifest.stops
          .map((s) => s.childId == updated.childId ? updated : s)
          .toList(),
    );
  }

  RouteManifest _mergeStops(
    RouteManifest manifest,
    List<models.RouteStop> updated,
  ) {
    final updatedMap = {for (final s in updated) s.childId: s};
    return RouteManifest(
      id: manifest.id,
      driverId: manifest.driverId,
      vanId: manifest.vanId,
      startedAt: manifest.startedAt,
      finishedAt: manifest.finishedAt,
      status: manifest.status,
      stops: manifest.stops.map((s) => updatedMap[s.childId] ?? s).toList(),
    );
  }
}
