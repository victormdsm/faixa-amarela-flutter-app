import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/enrollment.dart';
import '../providers/parent_portal_providers.dart';

class EnrollmentsController extends AsyncNotifier<List<Enrollment>> {
  @override
  Future<List<Enrollment>> build() async {
    return _load();
  }

  Future<List<Enrollment>> _load() async {
    final repo = ref.read(enrollmentsRepositoryProvider);
    return repo.getPendingEnrollments();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> accept(int id) async {
    final repo = ref.read(enrollmentsRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.acceptEnrollment(id);
      return _load();
    });
    _invalidatePortalLists();
  }

  Future<void> reject(int id) async {
    final repo = ref.read(enrollmentsRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.rejectEnrollment(id);
      return _load();
    });
    _invalidatePortalLists();
  }

  Future<void> cancel(int id) async {
    final repo = ref.read(enrollmentsRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.cancelEnrollment(id);
      return _load();
    });
    _invalidatePortalLists();
  }

  /// APP-16: accept/reject/cancel mudam rotas, embarques e a lista de
  /// crianças do responsável — invalida as listagens derivadas.
  void _invalidatePortalLists() {
    if (state.hasError) return;
    ref.invalidate(parentRoutesProvider);
    ref.invalidate(parentBoardingsProvider);
    ref.invalidate(parentChildrenProvider);
  }
}
