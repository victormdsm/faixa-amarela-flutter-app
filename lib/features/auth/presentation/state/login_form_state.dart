import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/validators.dart';
import '../../domain/entities/user_role.dart';

part 'login_form_state.freezed.dart';

@freezed
abstract class LoginFormState with _$LoginFormState {
  const LoginFormState._();

  const factory LoginFormState({
    required String email,
    required String password,
    required UserRole role,
    required bool obscurePassword,
    required bool isLoading,
    String? errorMessage,
  }) = _LoginFormState;

  factory LoginFormState.initial() => const LoginFormState(
    email: '',
    password: '',
    role: UserRole.parent,
    obscurePassword: true,
    isLoading: false,
  );

  bool get canSubmit {
    final loginOk = switch (role) {
      UserRole.parent => Validators.isValidEmail(email),
      UserRole.driver => Validators.loginIdentifier(email) == null,
    };
    return loginOk && password.trim().length >= 6 && !isLoading;
  }
}
