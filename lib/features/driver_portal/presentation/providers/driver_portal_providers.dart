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
import '../../../auth/presentation/state/app_session_controller.dart';
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
// Cache local (Hive, por userId) manda na abertura: com cache, o perfil é
// exibido imediatamente SEM chamar a API — nada de refetch automático por
// abertura de tela ou por watch. Dados frescos chegam apenas por:
//   (a) primeira vez sem cache (fetch na inicialização);
//   (b) botão "Sincronizar" da página de perfil ([refresh]);
//   (c) push `driver_profile_change_reviewed`, que invalida este provider
//       (evento, não polling — o rebuild busca na API, ver guard abaixo).
final driverProfileProvider =
    AsyncNotifierProvider<DriverProfileController, Map<String, dynamic>>(
      DriverProfileController.new,
    );

final driverProfileStorageProvider = Provider<DriverProfileStorage>(
  (ref) => DriverProfileStorage(),
);

/// Guard de sessão do cache do perfil: registra o userId cujo perfil já foi
/// entregue (cache ou API) nesta sessão do app.
///
/// Vive fora do [DriverProfileController] de propósito: invalidar o provider
/// recria o notifier (campos de instância zerariam), mas este Provider
/// simples nunca é invalidado — é o que permite distinguir "primeira
/// inicialização" (usa cache sem bater na API) de "rebuild por invalidação"
/// (push de aprovação: deve buscar dados frescos).
final driverProfileSessionGuardProvider = Provider<DriverProfileSessionGuard>(
  (ref) => DriverProfileSessionGuard(),
);

class DriverProfileSessionGuard {
  /// userId cujo perfil já foi entregue nesta sessão; null = ainda não carregou.
  int? loadedUserId;
}

class DriverProfileController extends AsyncNotifier<Map<String, dynamic>> {
  DriverProfileStorage get _storage => ref.read(driverProfileStorageProvider);

  int? get _sessionUserId =>
      ref.read(appSessionControllerProvider).session?.user.id;

  @override
  Future<Map<String, dynamic>> build() async {
    final userId = _sessionUserId;
    final guard = ref.read(driverProfileSessionGuardProvider);

    if (userId != null && guard.loadedUserId == userId) {
      // Rebuild por invalidação explícita (push de aprovação): busca dados
      // frescos. Se a rede falhar, cai no cache para não derrubar a tela.
      try {
        return await _fetch(userId);
      } catch (_) {
        final cached = _storage.load(userId);
        if (cached != null) return cached;
        rethrow;
      }
    }

    if (userId != null) {
      final cached = _storage.load(userId);
      if (cached != null) {
        // Cache presente: exibe imediatamente SEM chamar a API. A
        // sincronização passa a ser manual (botão) ou por evento (push).
        guard.loadedUserId = userId;
        return cached;
      }
    }

    // Primeira vez (sem cache): fetch inicial obrigatório.
    final fresh = await _fetch(userId);
    guard.loadedUserId = userId;
    return fresh;
  }

  Future<Map<String, dynamic>> _fetch(int? sessionUserId) async {
    final repo = ref.read(driverProfileRepositoryProvider);
    final profile = await repo.getDriverProfile();
    if (profile == null) {
      throw ApiException(message: 'Perfil do motorista nao encontrado.');
    }
    final json = profile.toJson();
    final cacheUserId = sessionUserId ?? profile.userId;
    if (cacheUserId > 0) {
      await _storage.save(cacheUserId, json);
    }
    return json;
  }

  /// Sincronização manual (botão "Sincronizar" da página de perfil).
  ///
  /// Mantém os dados atuais na tela enquanto busca (nada de loading full).
  /// Em caso de falha COM dados anteriores, o estado não é tocado — o cache
  /// segue visível — e o erro é propagado para o chamador exibir um aviso.
  /// Sem dados anteriores, comporta-se como o fetch inicial (loading/erro).
  Future<void> refresh() async {
    final hadValue = state.hasValue;
    if (!hadValue) {
      state = const AsyncValue.loading();
    }
    final userId = _sessionUserId;
    try {
      final fresh = await _fetch(userId);
      ref.read(driverProfileSessionGuardProvider).loadedUserId = userId;
      state = AsyncValue.data(fresh);
    } catch (e, st) {
      if (!hadValue) {
        state = AsyncValue.error(e, st);
      }
      rethrow;
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
