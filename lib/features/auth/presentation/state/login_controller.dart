import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/user_role.dart';
import '../providers/auth_providers.dart';
import 'app_session_controller.dart';
import 'login_form_state.dart';

part 'login_controller.g.dart';

@riverpod
class LoginController extends _$LoginController {
  @override
  LoginFormState build() => LoginFormState.initial();

  void setRole(UserRole role) {
    state = state.copyWith(role: role, errorMessage: null);
  }

  void setEmail(String value) {
    state = state.copyWith(email: value, errorMessage: null);
  }

  void setPassword(String value) {
    state = state.copyWith(password: value, errorMessage: null);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(
      obscurePassword: !state.obscurePassword,
      errorMessage: null,
    );
  }

  Future<bool> submit() async {
    final loginError = switch (state.role) {
      UserRole.parent => Validators.email(state.email),
      UserRole.driver => Validators.loginIdentifier(state.email),
    };
    final passwordError = Validators.password(state.password);
    if (loginError != null) {
      state = state.copyWith(errorMessage: loginError);
      return false;
    }
    if (passwordError != null) {
      state = state.copyWith(errorMessage: passwordError);
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final session = await ref
          .read(loginUseCaseProvider)
          .call(
            email: state.email.trim(),
            password: state.password,
            role: state.role,
          );
      ref
          .read(appSessionControllerProvider.notifier)
          .setSession(session, loginRole: state.role);
      // O registro de push é feito fora deste controller (autoDispose) para
      // evitar StateError quando o provider é descartado após o redirect.
      // Também só atualizamos o estado local se o controller ainda estiver
      // montado, pois o redirect pode ter removido a LoginPage.
      if (ref.mounted) {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } on ApiException catch (e) {
      if (ref.mounted) {
        state = state.copyWith(isLoading: false, errorMessage: e.message);
      }
      return false;
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Não foi possível realizar o login. Tente novamente.',
        );
      }
      return false;
    }
  }
}
