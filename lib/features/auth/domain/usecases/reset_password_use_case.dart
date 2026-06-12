import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String token,
    required String password,
    required String passwordConfirmation,
  }) {
    return _repository.resetPassword(
      token: token,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }
}
