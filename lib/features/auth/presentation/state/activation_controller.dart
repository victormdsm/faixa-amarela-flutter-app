import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_exception.dart';
import '../providers/auth_providers.dart';
import 'activation_state.dart';

part 'activation_controller.g.dart';

@riverpod
class ActivationController extends _$ActivationController {
  @override
  ActivationState build() => ActivationState.initial();

  void setEmailOrCpf(String value) {
    state = state.copyWith(emailOrCpf: value, errorMessage: null);
  }

  void setCode(String value) {
    state = state.copyWith(code: value, errorMessage: null);
  }

  Future<bool> submit() async {
    final emailOrCpf = state.emailOrCpf.trim();
    if (emailOrCpf.isEmpty) {
      state = state.copyWith(errorMessage: 'Informe o e-mail ou CPF.');
      return false;
    }

    final code = state.code.trim();
    if (code.length != 6) {
      state = state.copyWith(errorMessage: 'O código deve ter 6 dígitos.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, success: null);

    try {
      await ref
          .read(activateAccountUseCaseProvider)
          .call(emailOrCpf: emailOrCpf, code: code);
      state = state.copyWith(isLoading: false, success: true);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Não foi possível ativar a conta. Tente novamente.',
      );
      return false;
    }
  }
}
