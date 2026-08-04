import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/paginated_result.dart';
import '../../../../core/network/backend_config.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../data/nestjs_user_repository.dart';
import '../../../../domain/models/child.dart';
import '../../../../domain/models/enrollment.dart';
import '../../../../domain/repositories/children_repository.dart';
import '../../../../domain/repositories/enrollments_repository.dart';
import '../../data/nestjs_children_repository.dart';
import '../../data/nestjs_enrollments_repository.dart';
import '../../data/nestjs_parent_routing_repository.dart';
import '../../data/parent_realtime_service.dart';
import '../state/add_child_controller.dart';
import '../state/children_controller.dart';
import '../state/enrollments_controller.dart';
import '../state/parent_realtime_controller.dart';

final parentRoutingRepositoryProvider = Provider<NestjsParentRoutingRepository>(
  (ref) => NestjsParentRoutingRepository(ref.watch(dioProvider)),
);

final parentChildrenProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(childrenRepositoryProvider);
  final children = await repo.getChildren();
  return PaginatedResult<Child>(
    items: children,
    currentPage: 1,
    lastPage: 1,
    total: children.length,
  );
});

final parentRoutesProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(parentRoutingRepositoryProvider);
  return repo.getRoutes();
});

final parentBoardingsProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(parentRoutingRepositoryProvider);
  return repo.getBoardings();
});

// ─── Realtime (socket do acompanhamento da van) ────────────────────────────

/// Service realtime do pai. autoDispose: quando a tela de acompanhamento sai
/// (ou para de observar o controller), o socket é desconectado no dispose.
final parentRealtimeServiceProvider = Provider.autoDispose<ParentRealtimeService>(
  (ref) {
    // O gateway Socket.IO vive na origem da API (path padrão /socket.io),
    // não sob o prefixo /api/v1 — por isso appBaseUrl e não apiBaseUrl.
    final service = ParentRealtimeService(baseUrl: BackendConfig.appBaseUrl);
    ref.onDispose(service.dispose);
    return service;
  },
);

final parentRealtimeControllerProvider =
    NotifierProvider.autoDispose<ParentRealtimeController, ParentRealtimeState>(
      ParentRealtimeController.new,
    );

// ─── Typed repositories ────────────────────────────────────────────────────

final childrenRepositoryProvider = Provider<ChildrenRepository>(
  (ref) => NestjsChildrenRepository(ref.watch(dioProvider)),
);

final enrollmentsRepositoryProvider = Provider<EnrollmentsRepository>(
  (ref) => NestjsEnrollmentsRepository(ref.watch(dioProvider)),
);

// ─── Controllers ───────────────────────────────────────────────────────────

final childrenControllerProvider =
    AsyncNotifierProvider<ChildrenController, List<Child>>(
      ChildrenController.new,
    );

final enrollmentsControllerProvider =
    AsyncNotifierProvider<EnrollmentsController, List<Enrollment>>(
      EnrollmentsController.new,
    );

final addChildControllerProvider =
    AsyncNotifierProvider<AddChildController, void>(AddChildController.new);

final parentUserProfileProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getMe();
});
