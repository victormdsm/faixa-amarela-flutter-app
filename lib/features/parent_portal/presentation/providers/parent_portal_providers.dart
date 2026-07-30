import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/paginated_result.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../data/nestjs_user_repository.dart';
import '../../../../domain/models/child.dart';
import '../../../../domain/models/enrollment.dart';
import '../../../../domain/repositories/children_repository.dart';
import '../../../../domain/repositories/enrollments_repository.dart';
import '../../data/nestjs_children_repository.dart';
import '../../data/nestjs_enrollments_repository.dart';
import '../../data/nestjs_parent_routing_repository.dart';
import '../state/add_child_controller.dart';
import '../state/children_controller.dart';
import '../state/enrollments_controller.dart';

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
