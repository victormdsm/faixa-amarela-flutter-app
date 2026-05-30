import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/validators.dart';

part 'finalize_registration_state.freezed.dart';

@freezed
abstract class FinalizeRegistrationState with _$FinalizeRegistrationState {
  const FinalizeRegistrationState._();

  const factory FinalizeRegistrationState({
    required String login,
    required bool isLoading,
    String? errorMessage,
    String? successMessage,
  }) = _FinalizeRegistrationState;

  factory FinalizeRegistrationState.initial() =>
      const FinalizeRegistrationState(login: '', isLoading: false);

  bool get canSubmit => Validators.loginIdentifier(login) == null && !isLoading;
}
