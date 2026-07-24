import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/paginated_result.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../domain/models/driver_profile_change_request.dart';
import '../../../../domain/models/driver_route_summary.dart';
import '../../../../domain/models/enrollment.dart';
import '../../../../domain/models/route_manifest.dart';
import '../../../../domain/repositories/driver_repository.dart';
import '../../../../domain/repositories/enrollments_repository.dart';
import '../../../../domain/repositories/routes_repository.dart';
import '../../data/driver_profile_storage.dart';
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
  return PaginatedResult<DriverRouteSummary>(
    items: items.map(DriverRouteSummary.fromJson).toList(growable: false),
    currentPage: 1,
    lastPage: 1,
    total: items.length,
  );
});

// CANONICO: perfil do motorista via NestJS (/drivers/me).
//
// Carrega primeiro do cache local (Hive) para renderizar imediatamente; em
// seguida busca silenciosamente da API e atualiza a tela apenas se houver
// mudanças. O botão de refresh dispara [DriverProfileController.refresh].
final driverProfileProvider =
    AsyncNotifierProvider<DriverProfileController, Map<String, dynamic>>(
      DriverProfileController.new,
    );

final driverProfileStorageProvider = Provider<DriverProfileStorage>(
  (ref) => DriverProfileStorage(),
);

class DriverProfileController extends AsyncNotifier<Map<String, dynamic>> {
  DriverProfileStorage get _storage => ref.read(driverProfileStorageProvider);

  @override
  Future<Map<String, dynamic>> build() async {
    final cached = _storage.load();
    if (cached != null) {
      // Dispara refresh silencioso após o build concluir, mantendo o cache
      // visível enquanto a API responde.
      Future.delayed(Duration.zero, _refreshSilently);
      return cached;
    }
    return _fetch();
  }

  Future<Map<String, dynamic>> _fetch() async {
    final repo = ref.read(driverProfileRepositoryProvider);
    final profile = await repo.getDriverProfile();
    if (profile == null) {
      throw ApiException(message: 'Perfil do motorista nao encontrado.');
    }
    final json = profile.toJson();
    await _storage.save(json);
    return json;
  }

  Future<void> _refreshSilently() async {
    var disposed = false;
    ref.onDispose(() => disposed = true);

    try {
      final fresh = await _fetch();
      if (disposed) return;
      if (state.hasValue) {
        final current = state.value!;
        if (!const DeepCollectionEquality().equals(current, fresh)) {
          state = AsyncValue.data(fresh);
        }
      } else {
        state = AsyncValue.data(fresh);
      }
    } catch (e, st) {
      // Mantém o cache em caso de falha silenciosa; só propaga erro quando
      // não há dados anteriores.
      if (disposed) return;
      if (!state.hasValue) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Força uma nova consulta à API e atualiza o cache.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final fresh = await _fetch();
      state = AsyncValue.data(fresh);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

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

// CANONICO: historico de solicitacoes de alteracao de perfil do motorista.
final driverProfileChangeRequestsProvider = FutureProvider
    .autoDispose<List<DriverProfileChangeRequest>>((ref) async {
  final repo = ref.watch(driverProfileChangeRequestRepositoryProvider);
  return repo.listMyRequests();
});
