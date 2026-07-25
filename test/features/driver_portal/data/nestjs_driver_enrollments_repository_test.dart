import 'package:app_faixa_amarela/features/driver_portal/data/nestjs_driver_enrollments_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late NestjsDriverEnrollmentsRepository repository;

  setUp(() {
    dio = MockDio();
    repository = NestjsDriverEnrollmentsRepository(dio);
  });

  group('cancelEnrollment', () {
    test('puts to the driver cancel endpoint with an explicit empty body',
        () async {
      when(
        () => dio.put<dynamic>(
          '/driver/enrollments/7/cancel',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          data: const <String, dynamic>{'status': 'canceled'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/driver/enrollments/7/cancel'),
        ),
      );

      await repository.cancelEnrollment(7);

      final captured = verify(
        () => dio.put<dynamic>(
          '/driver/enrollments/7/cancel',
          data: captureAny(named: 'data'),
        ),
      ).captured;

      expect(captured[0], equals(const <String, dynamic>{}));
    });
  });
}
