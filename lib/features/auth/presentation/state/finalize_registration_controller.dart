import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';
import 'finalize_registration_state.dart';

part 'finalize_registration_controller.g.dart';

@riverpod
class FinalizeRegistrationController extends _$FinalizeRegistrationController {
  @override
  FinalizeRegistrationState build() => FinalizeRegistrationState.initial();

  void setLogin(String value) {
    state = state.copyWith(
      login: value,
      errorMessage: null,
      successMessage: null,
    );
  }

  Future<bool> submit() async {
    final loginError = Validators.loginIdentifier(state.login);
    if (loginError != null) {
      state = state.copyWith(errorMessage: loginError, successMessage: null);
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final login = state.login.trim();
      await ref.read(requestActivationLinkUseCaseProvider).call(login: login);
      state = state.copyWith(
        isLoading: false,
        successMessage:
            'Se o cadastro existir, enviamos um e-mail com o código de ativação para $login.',
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
        errorMessage: 'Falha ao solicitar o e-mail de finalização de cadastro.',
        successMessage: null,
      );
      return false;
    }
  }
}
