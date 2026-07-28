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
      final normalizedLogin = email.trim();
      final payload = _isEmail(normalizedLogin)
          ? <String, dynamic>{'email': normalizedLogin, 'password': password}
          : <String, dynamic>{
              'cpf': _digitsOnly(normalizedLogin),
              'password': password,
            };

      final response = await _dio.post<Map<String, dynamic>>(
        _loginEndpoint(role),
        data: payload,
      );

      final responseData = response.data;
      if (responseData == null) {
        throw ApiException(message: 'Resposta vazia da API no login.');
      }

      final session = AuthSession.fromJson(responseData);
      await _secureStorage.writeAccessToken(session.accessToken);
      if (session.hasRefreshToken) {
        await _secureStorage.writeRefreshToken(session.refreshToken!);
      }
      return session;
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<AuthSession> refreshSession(String refreshToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final payload = response.data;
      if (payload == null) {
        throw ApiException(message: 'Resposta vazia da API no refresh.');
      }

      final session = AuthSession.fromJson(payload);
      await _secureStorage.writeAccessToken(session.accessToken);
      if (session.hasRefreshToken) {
        await _secureStorage.writeRefreshToken(session.refreshToken!);
      }
      return session;
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> logout({String? refreshToken, bool allDevices = false}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/logout',
        data: <String, dynamic>{
          'refreshToken': refreshToken,
          'allDevices': allDevices,
        },
      );
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
    try {
      final normalized = login.trim();
      final payload = _isEmail(normalized)
          ? <String, dynamic>{'email': normalized}
          : <String, dynamic>{'cpf': _digitsOnly(normalized)};

      await _dio.post<Map<String, dynamic>>(
        '/auth/resend-activation',
        data: payload,
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static bool _isEmail(String value) => value.contains('@');

  static String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  @override
  Future<void> signUpParent({
    required String name,
    required String email,
    required String cpf,
    required String cellPhone,
    required String password,
    required String passwordConfirmation,
    bool acceptTerms = false,
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
          'acceptTerms': acceptTerms,
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
      final normalized = emailOrCpf.trim();
      final payload = _isEmail(normalized)
          ? <String, dynamic>{'email': normalized, 'code': code.trim()}
          : <String, dynamic>{
              'cpf': _digitsOnly(normalized),
              'code': code.trim(),
            };

      await _dio.post<Map<String, dynamic>>('/auth/activate', data: payload);
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
