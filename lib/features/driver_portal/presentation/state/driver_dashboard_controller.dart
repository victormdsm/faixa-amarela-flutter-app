import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final activeRoute = await routesRepo.getActiveRoute();
    return DriverDashboardState(profile: profile, activeRoute: activeRoute);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final driverRepo = ref.read(driverProfileRepositoryProvider);
      final routesRepo = ref.read(driverRoutesRepositoryProvider);
      final profile = await driverRepo.getDriverProfile();
      final activeRoute = await routesRepo.getActiveRoute();
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
  }
}
