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

    // Local-only update: backend does not yet expose a dedicated absent endpoint.
    final updatedStops = current.stops.map((stop) {
      if (stop.childId == childId) {
        return models.RouteStop(
          id: stop.id,
          childId: stop.childId,
          childName: stop.childName,
          schoolName: stop.schoolName,
          address: stop.address,
          sequence: stop.sequence,
          status: models.StopStatus.absent,
          boardedAt: stop.boardedAt,
          disembarkedAt: stop.disembarkedAt,
        );
      }
      return stop;
    }).toList();

    state = AsyncData(
      RouteManifest(
        id: current.id,
        driverId: current.driverId,
        vanId: current.vanId,
        startedAt: current.startedAt,
        finishedAt: current.finishedAt,
        status: current.status,
        stops: updatedStops,
      ),
    );
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
