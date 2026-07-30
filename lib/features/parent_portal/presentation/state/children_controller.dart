import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/child.dart';
import '../../../../domain/models/enrollment.dart';
import '../providers/parent_portal_providers.dart';

class ChildrenController extends AsyncNotifier<List<Child>> {
  @override
  Future<List<Child>> build() async {
    debugPrint('[ChildrenController] build iniciado');
    final result = await _load();
    debugPrint('[ChildrenController] build concluido: ${result.length} itens');
    return result;
  }

  Future<List<Child>> _load() async {
    final repo = ref.read(childrenRepositoryProvider);
    debugPrint('[ChildrenController] _load chamando repo.getChildren()');
    try {
      final children = await repo.getChildren();
      debugPrint(
        '[ChildrenController] _load retornou ${children.length} itens',
      );
      return children;
    } catch (e, st) {
      debugPrint('[ChildrenController] _load ERRO: $e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> delete(int id) async {
    final repo = ref.read(childrenRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.deleteChild(id);
      return _load();
    });
    // APP-15: mantém a listagem canônica do portal em dia após o delete.
    if (!state.hasError) {
      ref.invalidate(parentChildrenProvider);
    }
  }

  Future<Enrollment?> findActiveEnrollmentForChild(int childId) async {
    final repo = ref.read(enrollmentsRepositoryProvider);
    final active = await repo.getActiveEnrollments();
    for (final enrollment in active) {
      if (enrollment.childId == childId) {
        return enrollment;
      }
    }
    return null;
  }
}
