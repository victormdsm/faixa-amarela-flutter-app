import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';
import 'forgot_password_state.dart';

part 'forgot_password_controller.g.dart';

@riverpod
class ForgotPasswordController extends _$ForgotPasswordController {
  @override
  ForgotPasswordState build() => ForgotPasswordState.initial();

  void setEmail(String value) {
    state = state.copyWith(
      email: value,
      errorMessage: null,
      successMessage: null,
    );
  }

  Future<bool> submit() async {
    final emailError = Validators.email(state.email);
    if (emailError != null) {
      state = state.copyWith(errorMessage: emailError, successMessage: null);
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      await ref
          .read(requestPasswordResetUseCaseProvider)
          .call(email: state.email.trim());
      state = state.copyWith(
        isLoading: false,
        successMessage:
            'Enviamos instrucoes para redefinir a senha para ${state.email.trim()}.',
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
        errorMessage: 'Falha ao solicitar recuperação de senha.',
        successMessage: null,
      );
      return false;
    }
  }
}
