import '../entities/auth_session.dart';
import '../entities/user_role.dart';

abstract interface class AuthRepository {
  Future<AuthSession> signIn({
    required String email,
    required String password,
    required UserRole role,
  });

  Future<AuthSession?> refreshCurrentSession();

  Future<void> requestPasswordReset({required String email});

  Future<void> requestActivationLink({required String login});

  Future<void> signUpParent({
    required String name,
    required String email,
    required String cpf,
    required String cellPhone,
    required String password,
    required String passwordConfirmation,

    /// F10 (LGPD): o backend exige o aceite explícito dos termos
    /// (`acceptTerms: true`); sem ele responde 400
    /// ('É necessário aceitar os termos de uso e privacidade.').
    bool acceptTerms = false,
  });

  Future<void> activateAccount({
    required String emailOrCpf,
    required String code,
  });

  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  });
}
