import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/debouncer.dart';
import '../../../../core/utils/validators.dart';
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

  void search(String query) {
    // Aceita CPF (11 dígitos) ou o código da criança (UUID) — o backend
    // resolve ambos no mesmo endpoint (lookup-by-cpf, parâmetro flexível).
    final trimmed = query.trim();
    final String lookup;
    if (Validators.isUuid(trimmed)) {
      lookup = trimmed.toLowerCase();
    } else {
      final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length != 11) {
        state = AsyncError(
          Exception(
            'Informe um CPF valido com 11 digitos ou o codigo da crianca.',
          ),
          StackTrace.current,
        );
        return;
      }
      lookup = digits;
    }

    state = const AsyncLoading();

    _debouncer.run(() async {
      state = await AsyncValue.guard(() async {
        final result = await _repo.lookupChildByCpf(lookup);
        if (!result.found) {
          throw Exception(
            'Crianca nao encontrada. Verifique se o CPF ou codigo informado e o da crianca e se o responsavel ja cadastrou o dependente.',
          );
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
