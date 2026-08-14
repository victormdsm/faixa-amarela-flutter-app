import 'package:app_faixa_amarela/core/storage/secure_token_storage.dart';
import 'package:app_faixa_amarela/features/auth/data/repositories/nestjs_auth_repository.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/user_role.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockSecureTokenStorage extends Mock implements SecureTokenStorage {}

void main() {
  late NestjsAuthRepository repository;
  late MockDio dio;
  late MockSecureTokenStorage secureStorage;

  setUp(() {
    dio = MockDio();
    secureStorage = MockSecureTokenStorage();
    repository = NestjsAuthRepository(dio, secureStorage);
  });

  group('signIn', () {
    test('parent login calls correct endpoint and saves token', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/auth/user/login',
          data: {'email': 'user@email.com', 'password': 'secret'},
        ),
      ).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{
            'accessToken': 'nest_token',
            'tokenType': 'Bearer',
            'user': <String, dynamic>{
              'id': 1,
              'name': 'User',
              'email': 'user@email.com',
              'role': 'user',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );
      when(
        () => secureStorage.writeAccessToken('nest_token'),
      ).thenAnswer((_) async {});

      final session = await repository.signIn(
        email: 'user@email.com',
        password: 'secret',
        role: UserRole.parent,
      );

      expect(session.accessToken, 'nest_token');
      expect(session.user.roles, ['user']);
      verify(() => secureStorage.writeAccessToken('nest_token')).called(1);
    });

    test('driver login calls correct endpoint', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/auth/driver/login',
          data: {'email': 'driver@email.com', 'password': 'secret'},
        ),
      ).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{
            'accessToken': 'driver_token',
            'tokenType': 'Bearer',
            'user': <String, dynamic>{
              'id': 2,
              'name': 'Driver',
              'email': 'driver@email.com',
              'role': 'driver',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );
      when(
        () => secureStorage.writeAccessToken('driver_token'),
      ).thenAnswer((_) async {});

      final session = await repository.signIn(
        email: 'driver@email.com',
        password: 'secret',
        role: UserRole.driver,
      );

      expect(session.accessToken, 'driver_token');
      expect(session.user.isDriverAppRole, true);
    });
  });

  group('signUpParent', () {
    test('calls /api/v1/auth/user/register with correct payload', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/auth/user/register',
          data: {
            'name': 'Maria',
            'email': 'maria@email.com',
            'cpf': '12345678901',
            'cellPhone': '11999999999',
            'password': 'secret',
            'acceptTerms': true,
          },
        ),
      ).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{},
          statusCode: 201,
          requestOptions: RequestOptions(),
        ),
      );

      await repository.signUpParent(
        name: 'Maria',
        email: 'maria@email.com',
        cpf: '12345678901',
        cellPhone: '11999999999',
        password: 'secret',
        passwordConfirmation: 'secret',
        acceptTerms: true,
      );

      verify(
        () => dio.post<Map<String, dynamic>>(
          '/auth/user/register',
          data: any(named: 'data'),
        ),
      ).called(1);
    });
  });

  group('activateAccount', () {
    test('calls /api/v1/auth/activate with email and code', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/auth/activate',
          data: {'email': 'maria@email.com', 'code': '123456'},
        ),
      ).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{},
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      await repository.activateAccount(
        emailOrCpf: 'maria@email.com',
        code: '123456',
      );

      verify(
        () => dio.post<Map<String, dynamic>>(
          '/auth/activate',
          data: {'email': 'maria@email.com', 'code': '123456'},
        ),
      ).called(1);
    });
  });

  group('requestPasswordReset', () {
    test('calls /api/v1/auth/forgot-password', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/auth/forgot-password',
          data: {'email': 'user@email.com'},
        ),
      ).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{},
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      await repository.requestPasswordReset(email: 'user@email.com');

      verify(
        () => dio.post<Map<String, dynamic>>(
          '/auth/forgot-password',
          data: {'email': 'user@email.com'},
        ),
      ).called(1);
    });
  });

  group('resetPassword', () {
    test('calls /api/v1/auth/reset-password', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/auth/reset-password',
          data: {
            'email': 'user@email.com',
            'token': 'tok',
            'new_password': 'new_secret',
          },
        ),
      ).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{},
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      await repository.resetPassword(
        email: 'user@email.com',
        token: 'tok',
        password: 'new_secret',
        passwordConfirmation: 'new_secret',
      );

      verify(
        () => dio.post<Map<String, dynamic>>(
          '/auth/reset-password',
          data: {
            'email': 'user@email.com',
            'token': 'tok',
            'new_password': 'new_secret',
          },
        ),
      ).called(1);
    });
  });

  group('requestActivationLink', () {
    test('calls /auth/resend-activation with email', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/auth/resend-activation',
          data: {'email': 'user@email.com'},
        ),
      ).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{},
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      await repository.requestActivationLink(login: 'user@email.com');

      verify(
        () => dio.post<Map<String, dynamic>>(
          '/auth/resend-activation',
          data: {'email': 'user@email.com'},
        ),
      ).called(1);
    });

    test('calls /auth/resend-activation with cleaned cpf', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/auth/resend-activation',
          data: {'cpf': '12345678901'},
        ),
      ).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{},
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      await repository.requestActivationLink(login: '123.456.789-01');

      verify(
        () => dio.post<Map<String, dynamic>>(
          '/auth/resend-activation',
          data: {'cpf': '12345678901'},
        ),
      ).called(1);
    });
  });
}
