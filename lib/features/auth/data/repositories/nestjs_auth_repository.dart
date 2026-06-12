import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/secure_token_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';

class NestjsAuthRepository implements AuthRepository {
  NestjsAuthRepository(this._dio, this._secureStorage);

  final Dio _dio;
  final SecureTokenStorage _secureStorage;

  String _loginEndpoint(UserRole role) => switch (role) {
    UserRole.parent => '/auth/user/login',
    UserRole.driver => '/auth/driver/login',
  };

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _loginEndpoint(role),
        data: {'email': email.trim(), 'password': password},
      );

      final data = response.data;
      if (data == null) {
        throw ApiException(message: 'Resposta vazia da API no login.');
      }

      final payload = data['data'] as Map<String, dynamic>? ?? data;
      final session = AuthSession.fromJson(payload);
      await _secureStorage.writeAccessToken(session.accessToken);
      return session;
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {'email': email.trim()},
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> requestActivationLink({required String login}) async {
    throw ApiException(
      message: 'Reenvio de link de ativacao nao suportado neste backend.',
    );
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
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/user/register',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'cpf': cpf.trim(),
          'cellPhone': cellPhone.trim(),
          'password': password,
        },
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> activateAccount({
    required String emailOrCpf,
    required String code,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/activate',
        data: {'email': emailOrCpf.trim(), 'code': code.trim()},
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/reset-password',
        data: {'token': token, 'newPassword': password},
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
