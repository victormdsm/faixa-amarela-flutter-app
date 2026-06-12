import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_exception.dart';
import '../providers/auth_providers.dart';
import 'reset_password_state.dart';

part 'reset_password_controller.g.dart';

@riverpod
class ResetPasswordController extends _$ResetPasswordController {
  @override
  ResetPasswordState build() => ResetPasswordState.initial();

  void setToken(String value) {
    state = state.copyWith(
      token: value,
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

  Future<bool> submit() async {
    if (state.token.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Informe o token de recuperacao.');
      return false;
    }
    if (state.password.isEmpty) {
      state = state.copyWith(errorMessage: 'Informe a nova senha.');
      return false;
    }
    if (state.password != state.passwordConfirmation) {
      state = state.copyWith(errorMessage: 'As senhas nao coincidem.');
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
            token: state.token.trim(),
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
        errorMessage: 'Falha ao redefinir a senha.',
        successMessage: null,
      );
      return false;
    }
  }
}
