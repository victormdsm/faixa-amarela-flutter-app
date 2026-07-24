import 'package:app_faixa_amarela/core/network/auth_interceptor.dart';
import 'package:app_faixa_amarela/core/storage/secure_token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockSecureTokenStorage extends Mock implements SecureTokenStorage {}

class _NoOpErrorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException err) {}

  @override
  void resolve(Response response, [bool callFollowingErrorInterceptor = false]) {}

  @override
  void reject(DioException err, [bool callFollowingErrorInterceptor = false]) {}
}

void main() {
  group('AuthInterceptor', () {
    late MockDio dio;
    late MockSecureTokenStorage secureStorage;
    late AuthInterceptor interceptor;

    setUp(() {
      dio = MockDio();
      secureStorage = MockSecureTokenStorage();
      interceptor = AuthInterceptor(
        dio: dio,
        secureStorage: secureStorage,
      );

      when(() => secureStorage.clearAll()).thenAnswer((_) async {});
      when(() => secureStorage.readAccessToken()).thenAnswer((_) async => null);
      when(() => secureStorage.readRefreshToken()).thenAnswer((_) async => null);
    });

    test(
      'onError does not clear session or refresh on 401 for public auth endpoints',
      () async {
        for (final path in [
          '/auth/user/login',
          '/auth/driver/login',
          '/auth/admin/login',
          '/auth/user/register',
          '/auth/activate',
          '/auth/forgot-password',
          '/auth/reset-password',
        ]) {
          final requestOptions = RequestOptions(
            path: path,
            baseUrl: 'https://example.com',
          );
          final error = DioException(
            requestOptions: requestOptions,
            response: Response<dynamic>(
              requestOptions: requestOptions,
              statusCode: 401,
              data: {'message': 'Credenciais invalidas.'},
            ),
            type: DioExceptionType.badResponse,
          );

          await interceptor.onError(error, _NoOpErrorHandler());
        }

        verifyNever(() => secureStorage.clearAll());
        verifyNever(() => secureStorage.readRefreshToken());
      },
    );
  });
}
