import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/validators.dart';

part 'forgot_password_state.freezed.dart';

@freezed
abstract class ForgotPasswordState with _$ForgotPasswordState {
  const ForgotPasswordState._();

  const factory ForgotPasswordState({
    required String email,
    required bool isLoading,
    String? errorMessage,
    String? successMessage,
  }) = _ForgotPasswordState;

  factory ForgotPasswordState.initial() =>
      const ForgotPasswordState(email: '', isLoading: false);

  bool get canSubmit => Validators.isValidEmail(email) && !isLoading;
}
