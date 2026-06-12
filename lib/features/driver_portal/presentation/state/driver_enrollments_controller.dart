import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/enrollment.dart';
import '../providers/driver_portal_providers.dart';

class DriverEnrollmentsController extends AsyncNotifier<List<Enrollment>> {
  Future<List<Enrollment>> _load() async {
    final repo = ref.read(driverEnrollmentsRepositoryProvider);
    return repo.getMyEnrollments();
  }

  @override
  Future<List<Enrollment>> build() async => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}
