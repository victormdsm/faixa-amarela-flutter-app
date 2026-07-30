import 'package:app_faixa_amarela/data/nestjs_user_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

DioException _badRequest(String path, int statusCode, String message) {
  final options = RequestOptions(path: path);
  return DioException(
    requestOptions: options,
    response: Response<Map<String, dynamic>>(
      requestOptions: options,
      statusCode: statusCode,
      data: {'message': message},
    ),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  late MockDio dio;
  late NestjsUserRepository repository;

  setUp(() {
    dio = MockDio();
    repository = NestjsUserRepository(dio);
  });

  group('changePassword (APP-05)', () {
    test('sends currentPassword and newPassword to /users/me/password', () async {
      when(
        () => dio.put<Map<String, dynamic>>(
          '/users/me/password',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: const <String, dynamic>{},
          statusCode: 204,
          requestOptions: RequestOptions(path: '/users/me/password'),
        ),
      );

      await repository.changePassword(
        currentPassword: 'senha-atual',
        newPassword: 'nova-senha-123',
      );

      final captured = verify(
        () => dio.put<Map<String, dynamic>>(
          '/users/me/password',
          data: captureAny(named: 'data'),
        ),
      ).captured;
      final payload = captured.single as Map<String, dynamic>;
      expect(payload, {
        'currentPassword': 'senha-atual',
        'newPassword': 'nova-senha-123',
      });
    });

    test('surfaces the backend message when the current password is wrong', () async {
      when(
        () => dio.put<Map<String, dynamic>>(
          '/users/me/password',
          data: any(named: 'data'),
        ),
      ).thenThrow(_badRequest('/users/me/password', 401, 'Senha atual incorreta.'));

      await expectLater(
        () => repository.changePassword(
          currentPassword: 'errada',
          newPassword: 'nova-senha-123',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Senha atual incorreta.'),
          ),
        ),
      );
    });
  });
}
