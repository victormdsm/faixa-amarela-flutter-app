import '../repositories/auth_repository.dart';

class ActivateAccountUseCase {
  const ActivateAccountUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String emailOrCpf, required String code}) {
    return _repository.activateAccount(emailOrCpf: emailOrCpf, code: code);
  }
}
