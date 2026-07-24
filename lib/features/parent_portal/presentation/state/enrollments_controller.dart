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
  }

  Future<void> reject(int id) async {
    final repo = ref.read(enrollmentsRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.rejectEnrollment(id);
      return _load();
    });
  }

  Future<void> cancel(int id) async {
    final repo = ref.read(enrollmentsRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.cancelEnrollment(id);
      return _load();
    });
  }
}
