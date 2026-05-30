import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';

const _wrongAccessMessage =
    'Meio de acesso incorreto. Use o canal adequado para sua conta.';

class LaravelAuthRepository implements AuthRepository {
  LaravelAuthRepository(this._dio);

  final Dio _dio;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          if (role == UserRole.parent) 'email': email,
          if (role == UserRole.driver) 'login': email,
          'password': password,
          'device_name': 'flutter-app',
        },
      );

      final data = response.data;
      if (data == null) {
        throw ApiException(message: 'Resposta vazia da API no login.');
      }

      final session = AuthSession.fromJson(data);
      if (session.user.isAdmin) {
        throw ApiException(message: _wrongAccessMessage, statusCode: 403);
      }

      final isRoleAllowed = switch (role) {
        UserRole.parent => session.user.isParent,
        UserRole.driver => session.user.isDriver,
      };

      if (!isRoleAllowed) {
        throw ApiException(message: _wrongAccessMessage, statusCode: 403);
      }

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
        data: {'email': email},
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> requestActivationLink({required String login}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/resend-activation',
        data: {
          if (_isEmail(login)) 'email': login.trim() else 'login': login.trim(),
        },
      );
    } catch (error) {
      throw ApiException.fromDio(error);
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
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/register-parent',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'cpf': cpf.trim(),
          'cell_phone': cellPhone.trim(),
          'password': password,
          'password_confirmation': passwordConfirmation,
          'device_name': 'flutter-app',
        },
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> logout(String authorizationHeader) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/logout',
        options: Options(headers: {'Authorization': authorizationHeader}),
      );
    } catch (_) {
      // Mantem o logout local mesmo se a API falhar.
    }
  }

  bool _isEmail(String value) {
    final trimmed = value.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
  }
}
