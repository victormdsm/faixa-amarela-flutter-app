import 'package:freezed_annotation/freezed_annotation.dart';

part 'activation_state.freezed.dart';

@freezed
abstract class ActivationState with _$ActivationState {
  const ActivationState._();

  const factory ActivationState({
    required String emailOrCpf,
    required String code,
    required bool isLoading,
    String? errorMessage,
    bool? success,
  }) = _ActivationState;

  factory ActivationState.initial() =>
      const ActivationState(emailOrCpf: '', code: '', isLoading: false);

  bool get canSubmit =>
      emailOrCpf.trim().isNotEmpty && code.trim().length == 6 && !isLoading;
}
