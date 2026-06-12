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
    String? errorMessage,
    String? successMessage,
  }) = _ResetPasswordState;

  factory ResetPasswordState.initial() => const ResetPasswordState(
    token: '',
    password: '',
    passwordConfirmation: '',
    isLoading: false,
  );

  bool get canSubmit =>
      token.isNotEmpty &&
      password.isNotEmpty &&
      password == passwordConfirmation &&
      !isLoading;
}
