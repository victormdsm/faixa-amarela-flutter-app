import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../domain/models/driver_profile.dart';
import '../../../../domain/models/route_manifest.dart';
import '../providers/driver_portal_providers.dart';

class DriverDashboardState {
  const DriverDashboardState({this.profile, this.activeRoute});

  final DriverProfile? profile;
  final RouteManifest? activeRoute;

  DriverDashboardState copyWith({
    DriverProfile? profile,
    RouteManifest? activeRoute,
  }) {
    return DriverDashboardState(
      profile: profile ?? this.profile,
      activeRoute: activeRoute ?? this.activeRoute,
    );
  }
}

class DriverDashboardController extends AsyncNotifier<DriverDashboardState> {
  @override
  Future<DriverDashboardState> build() async {
    final driverRepo = ref.read(driverProfileRepositoryProvider);
    final routesRepo = ref.read(driverRoutesRepositoryProvider);
    final profile = await driverRepo.getDriverProfile();
    // APP-14: somente 404 significa "sem rota ativa" (null). Qualquer outro
    // erro (rede, 5xx) propaga e vira estado de erro — nunca "sem rota"
    // silencioso.
    RouteManifest? activeRoute;
    try {
      activeRoute = await routesRepo.getActiveRoute();
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
      activeRoute = null;
    }
    return DriverDashboardState(profile: profile, activeRoute: activeRoute);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final driverRepo = ref.read(driverProfileRepositoryProvider);
      final routesRepo = ref.read(driverRoutesRepositoryProvider);
      final profile = await driverRepo.getDriverProfile();
      RouteManifest? activeRoute;
      try {
        activeRoute = await routesRepo.getActiveRoute();
      } on ApiException catch (e) {
        if (e.statusCode != 404) rethrow;
        activeRoute = null;
      }
      return DriverDashboardState(profile: profile, activeRoute: activeRoute);
    });
  }

  Future<void> startRoute() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final driverRepo = ref.read(driverProfileRepositoryProvider);
      final routesRepo = ref.read(driverRoutesRepositoryProvider);
      final activeRoute = await routesRepo.startRoute();
      final profile = await driverRepo.getDriverProfile();
      return DriverDashboardState(profile: profile, activeRoute: activeRoute);
    });
    // APP-17: rota iniciada — mantém execução e lista de rotas em dia.
    if (!state.hasError) {
      ref.invalidate(driverRouteControllerProvider);
      ref.invalidate(driverRoutesProvider);
    }
  }
}
