import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/debouncer.dart';
import '../../../../domain/repositories/enrollments_repository.dart';
import '../providers/driver_portal_providers.dart';

class DriverLookupController extends Notifier<AsyncValue<ChildLookupResult?>> {
  late final Debouncer _debouncer;

  EnrollmentsRepository get _repo =>
      ref.read(driverEnrollmentsRepositoryProvider);

  @override
  AsyncValue<ChildLookupResult?> build() {
    _debouncer = Debouncer(delay: const Duration(milliseconds: 600));
    ref.onDispose(_debouncer.dispose);
    return const AsyncData(null);
  }

  void search(String cpf) {
    final cleaned = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length != 11) {
      state = AsyncError(
        Exception('Informe um CPF valido com 11 digitos.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();

    _debouncer.run(() async {
      state = await AsyncValue.guard(() async {
        final result = await _repo.lookupChildByCpf(cleaned);
        if (!result.found) {
          throw Exception('Crianca nao encontrada para este CPF.');
        }
        return result;
      });
    });
  }

  Future<void> requestEnrollment(int childId) async {
    await _repo.requestEnrollment(childId);
  }

  void clear() {
    _debouncer.cancel();
    state = const AsyncData(null);
  }
}
