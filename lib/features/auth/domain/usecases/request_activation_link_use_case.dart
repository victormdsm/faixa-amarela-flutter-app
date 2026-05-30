import '../repositories/auth_repository.dart';

class RequestActivationLinkUseCase {
  const RequestActivationLinkUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String login}) {
    return _repository.requestActivationLink(login: login);
  }
}
