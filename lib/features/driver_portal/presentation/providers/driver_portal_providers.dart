import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/paginated_result.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../domain/models/enrollment.dart';
import '../../../../domain/models/route_manifest.dart';
import '../../../../domain/repositories/driver_repository.dart';
import '../../../../domain/repositories/enrollments_repository.dart';
import '../../../../domain/repositories/routes_repository.dart';
import '../../data/nestjs_driver_enrollments_repository.dart';
import '../../data/nestjs_driver_profile_change_request_repository.dart';
import '../../data/nestjs_driver_repository.dart';
import '../../data/nestjs_routes_repository.dart';
import '../state/driver_dashboard_controller.dart';
import '../state/driver_enrollments_controller.dart';
import '../state/driver_lookup_controller.dart';
import '../state/driver_route_controller.dart';

// CANONICO: listagem de rotas do motorista via NestJS.
final driverRoutesProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(driverRoutesRepositoryProvider);
  final items = await repo.listDriverRoutes();
  return PaginatedResult<Map<String, dynamic>>(
    items: items,
    currentPage: 1,
    lastPage: 1,
    total: items.length,
  );
});

// CANONICO: perfil do motorista via NestJS (/drivers/me).
// Not autoDispose — profile and van image stay cached in memory for the session.
final driverProfileProvider = FutureProvider((ref) async {
  final repo = ref.watch(driverProfileRepositoryProvider);
  final profile = await repo.getDriverProfile();
  if (profile == null) {
    throw ApiException(message: 'Perfil do motorista nao encontrado.');
  }
  return profile.toJson();
});

// Presets legados nao possuem backend NestJS. Desativado ate decisao de produto.
// final driverRoutePresetsProvider = FutureProvider.autoDispose((ref) async { ... });

// ---------------------------------------------------------------------------
// New NestJS repository providers
// ---------------------------------------------------------------------------

final driverEnrollmentsRepositoryProvider = Provider<EnrollmentsRepository>(
  (ref) => NestjsDriverEnrollmentsRepository(ref.watch(dioProvider)),
);

final driverRoutesRepositoryProvider = Provider<RoutesRepository>(
  (ref) => NestjsRoutesRepository(ref.watch(dioProvider)),
);

final driverProfileRepositoryProvider = Provider<DriverRepository>(
  (ref) => NestjsDriverRepository(ref.watch(dioProvider)),
);

final driverProfileChangeRequestRepositoryProvider =
    Provider<NestjsDriverProfileChangeRequestRepository>(
      (ref) =>
          NestjsDriverProfileChangeRequestRepository(ref.watch(dioProvider)),
    );

// ---------------------------------------------------------------------------
// New controller providers
// ---------------------------------------------------------------------------

final driverDashboardControllerProvider =
    AsyncNotifierProvider<DriverDashboardController, DriverDashboardState>(
      DriverDashboardController.new,
    );

final driverLookupControllerProvider =
    NotifierProvider<DriverLookupController, AsyncValue<ChildLookupResult?>>(
      DriverLookupController.new,
    );

final driverRouteControllerProvider =
    AsyncNotifierProvider<DriverRouteController, RouteManifest?>(
      DriverRouteController.new,
    );

final driverEnrollmentsControllerProvider =
    AsyncNotifierProvider<DriverEnrollmentsController, List<Enrollment>>(
      DriverEnrollmentsController.new,
    );
