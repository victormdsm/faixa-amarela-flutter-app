import '../entities/auth_session.dart';
import '../entities/user_role.dart';

abstract interface class AuthRepository {
  Future<AuthSession> signIn({
    required String email,
    required String password,
    required UserRole role,
  });

  Future<void> requestPasswordReset({required String email});

  Future<void> requestActivationLink({required String login});

  Future<void> signUpParent({
    required String name,
    required String email,
    required String cpf,
    required String cellPhone,
    required String password,
    required String passwordConfirmation,
  });
}
