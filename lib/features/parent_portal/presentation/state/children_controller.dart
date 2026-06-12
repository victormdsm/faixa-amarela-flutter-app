import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/child.dart';
import '../providers/parent_portal_providers.dart';

class ChildrenController extends AsyncNotifier<List<Child>> {
  @override
  Future<List<Child>> build() async {
    return _load();
  }

  Future<List<Child>> _load() async {
    final repo = ref.read(childrenRepositoryProvider);
    return repo.getChildren();
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
  }
}
