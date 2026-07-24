@Tags(['prod'])
library;

// ignore_for_file: avoid_print

import 'package:app_faixa_amarela/core/network/nestjs_response_unwrap_interceptor.dart';
import 'package:app_faixa_amarela/core/storage/secure_token_storage.dart';
import 'package:app_faixa_amarela/features/auth/data/repositories/nestjs_auth_repository.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/user_role.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NestjsAuthRepository E2E', () {
    late Dio dio;
    late SecureTokenStorage storage;
    late NestjsAuthRepository repo;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.faixaamarela.com.br/api/v1',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      dio.interceptors.add(NestjsResponseUnwrapInterceptor());
      storage = SecureTokenStorage();
      repo = NestjsAuthRepository(dio, storage);
    });

    test('login as parent returns valid session and stores token', () async {
      final session = await repo.signIn(
        email: 'aoextremogames@gmail.com',
        password: 'Escolabetta1234',
        role: UserRole.parent,
      );

      expect(session.accessToken, isNotEmpty);
      expect(session.tokenType, 'Bearer');
      expect(session.user.id, 723);
      expect(session.user.name, 'Victor - teste');
      expect(session.user.email, 'aoextremogames@gmail.com');
      expect(session.user.isParent, isTrue);
      expect(session.user.isActivated, isTrue);

      final storedToken = await storage.readAccessToken();
      expect(storedToken, session.accessToken);
    });

    test('login as driver returns valid session with driver role', () async {
      final session = await repo.signIn(
        email: 'aoextremogames@gmail.com',
        password: 'Escolabetta1234',
        role: UserRole.driver,
      );

      expect(session.accessToken, isNotEmpty);
      expect(session.user.isDriver, isTrue);
    });

    test('wrong password throws ApiException', () async {
      expect(
        () => repo.signIn(
          email: 'aoextremogames@gmail.com',
          password: 'wrongpassword',
          role: UserRole.parent,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
