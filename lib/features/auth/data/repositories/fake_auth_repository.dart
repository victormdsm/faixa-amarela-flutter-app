import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (password.trim().length < 6) {
      throw const AuthException('Senha invalida.');
    }

    if (email.trim().toLowerCase().contains('bloqueado')) {
      throw const AuthException(
        'Conta temporariamente bloqueada. Tente novamente em alguns minutos.',
      );
    }

    if (role == UserRole.driver && email.trim().toLowerCase().contains('pai')) {
      throw const AuthException(
        'Este e-mail parece ser de pais. Troque o perfil antes de entrar.',
      );
    }

    return AuthSession(
      accessToken: 'fake-token',
      tokenType: 'Bearer',
      user: AuthUser(
        id: 1,
        name: 'Usuario Fake',
        email: email,
        role: role == UserRole.parent ? 'parent' : 'driver',
      ),
    );
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (email.trim().toLowerCase().contains('naocadastrado')) {
      throw const AuthException('E-mail nao encontrado na base.');
    }
  }

  @override
  Future<void> requestActivationLink({required String login}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (login.trim().toLowerCase().contains('invalido')) {
      throw const AuthException(
        'Nao foi possivel reenviar o e-mail de finalizacao.',
      );
    }
  }

  @override
  Future<void> signUpParent({
    required String name,
    required String email,
    required String cpf,
    required String cellPhone,
    required String password,
    required String passwordConfirmation,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (password != passwordConfirmation) {
      throw const AuthException('A confirmacao de senha nao confere.');
    }
    if (password.trim().length < 6) {
      throw const AuthException('A senha deve ter pelo menos 6 caracteres.');
    }
  }

  @override
  Future<void> activateAccount({
    required String emailOrCpf,
    required String code,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (code != '123456') {
      throw const AuthException('Codigo de ativacao invalido.');
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (password != passwordConfirmation) {
      throw const AuthException('A confirmacao de senha nao confere.');
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
