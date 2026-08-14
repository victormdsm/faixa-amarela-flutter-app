import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/utils/validators.dart';
import '../../../../domain/repositories/enrollments_repository.dart';
import '../providers/driver_portal_providers.dart';

class DriverLookupController extends Notifier<AsyncValue<ChildLookupResult?>> {
  /// Mensagem exibida quando a busca não é um código UUID válido — alinhada
  /// com o 400 do backend para o mesmo caso.
  static const String invalidCodeMessage =
      'Use o código da criança para buscar. Peça ao responsável que '
      'compartilhe o código no aplicativo.';

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
    // Aceita SOMENTE o código da criança (UUID v4) — o backend removeu o
    // lookup por CPF/RG (LGPD) e responde 400 para documentos.
    final code = query.trim();
    if (!Validators.isUuid(code)) {
      // ValidationFailure (AppFailure): a UI exibe `message` como está —
      // Exception genérica seria engolida pelo AppErrorReporter.
      state = AsyncError(
        const ValidationFailure(message: invalidCodeMessage),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();

    _debouncer.run(() async {
      state = await AsyncValue.guard(() async {
        final result = await _repo.lookupChildByCode(code.toLowerCase());
        if (!result.found) {
          throw Exception(
            'Crianca nao encontrada. Verifique o codigo informado e se o responsavel ja cadastrou o dependente.',
          );
        }
        return result;
      });
    });
  }

  Future<void> requestEnrollment(String childUuid) async {
    await _repo.requestEnrollment(childUuid);
  }

  void clear() {
    _debouncer.cancel();
    state = const AsyncData(null);
  }
}
