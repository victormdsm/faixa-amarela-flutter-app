import 'package:freezed_annotation/freezed_annotation.dart';

part 'reset_password_state.freezed.dart';

@freezed
abstract class ResetPasswordState with _$ResetPasswordState {
  const ResetPasswordState._();

  const factory ResetPasswordState({
    required String token,
    required String password,
    required String passwordConfirmation,
    required bool isLoading,
    required bool obscurePassword,
    required bool obscurePasswordConfirmation,
    String? errorMessage,
    String? successMessage,
  }) = _ResetPasswordState;

  factory ResetPasswordState.initial() => const ResetPasswordState(
    token: '',
    password: '',
    passwordConfirmation: '',
    isLoading: false,
    obscurePassword: true,
    obscurePasswordConfirmation: true,
  );

  bool get canSubmit =>
      token.trim().isNotEmpty &&
      password.length >= 6 &&
      password == passwordConfirmation &&
      password.contains(RegExp(r'[A-Za-z]')) &&
      password.contains(RegExp(r'[0-9]')) &&
      !isLoading;
}
