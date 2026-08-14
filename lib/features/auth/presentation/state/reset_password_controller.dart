import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_exception.dart';
import '../providers/auth_providers.dart';
import 'reset_password_state.dart';

part 'reset_password_controller.g.dart';

@riverpod
class ResetPasswordController extends _$ResetPasswordController {
  @override
  ResetPasswordState build() => ResetPasswordState.initial();

  void setEmail(String value) {
    state = state.copyWith(
      email: value,
      errorMessage: null,
      successMessage: null,
    );
  }

  void setToken(String value) {
    state = state.copyWith(
      token: value.trim().toUpperCase(),
      errorMessage: null,
      successMessage: null,
    );
  }

  void setPassword(String value) {
    state = state.copyWith(
      password: value,
      errorMessage: null,
      successMessage: null,
    );
  }

  void setPasswordConfirmation(String value) {
    state = state.copyWith(
      passwordConfirmation: value,
      errorMessage: null,
      successMessage: null,
    );
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void togglePasswordConfirmationVisibility() {
    state = state.copyWith(
      obscurePasswordConfirmation: !state.obscurePasswordConfirmation,
    );
  }

  Future<bool> submit() async {
    final email = state.email.trim();
    if (email.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Informe o e-mail cadastrado.',
      );
      return false;
    }
    final token = state.token.trim();
    if (token.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Informe o código de recuperação enviado por e-mail.',
      );
      return false;
    }
    if (state.password.length < 6) {
      state = state.copyWith(
        errorMessage: 'A senha deve ter pelo menos 6 caracteres.',
      );
      return false;
    }
    if (!state.password.contains(RegExp(r'[A-Za-z]'))) {
      state = state.copyWith(
        errorMessage: 'A senha deve conter pelo menos uma letra.',
      );
      return false;
    }
    if (!state.password.contains(RegExp(r'[0-9]'))) {
      state = state.copyWith(
        errorMessage: 'A senha deve conter pelo menos um número.',
      );
      return false;
    }
    if (state.password != state.passwordConfirmation) {
      state = state.copyWith(errorMessage: 'As senhas não coincidem.');
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      await ref
          .read(resetPasswordUseCaseProvider)
          .call(
            email: email,
            token: token,
            password: state.password,
            passwordConfirmation: state.passwordConfirmation,
          );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Senha redefinida com sucesso!',
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        successMessage: null,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Falha ao redefinir a senha. Tente novamente.',
        successMessage: null,
      );
      return false;
    }
  }
}
