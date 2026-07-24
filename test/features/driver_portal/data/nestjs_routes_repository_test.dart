import 'package:app_faixa_amarela/domain/models/route_manifest.dart';
import 'package:app_faixa_amarela/features/driver_portal/data/nestjs_routes_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late NestjsRoutesRepository repository;

  setUp(() {
    dio = MockDio();
    repository = NestjsRoutesRepository(dio);
  });

  group('finishRoute', () {
    test(
      'sends an explicit empty body and does not set application/json content-type',
      () async {
        when(
          () => dio.post<Map<String, dynamic>>(
            '/driver/routes/42/finish',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            data: const <String, dynamic>{},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/driver/routes/42/finish'),
          ),
        );

        await repository.finishRoute(42);

        final captured = verify(
          () => dio.post<Map<String, dynamic>>(
            '/driver/routes/42/finish',
            data: captureAny(named: 'data'),
            options: captureAny(named: 'options'),
          ),
        ).captured;

        expect(captured[0], equals(const <String, dynamic>{}));
        final options = captured[1] as Options?;
        expect(options?.contentType, isNot(equals('application/json')));
      },
    );
  });

  group('startRoute', () {
    test('sends an explicit empty body to avoid empty json body issues', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/driver/routes/start',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: const <String, dynamic>{
            'manifest': <String, dynamic>{},
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/driver/routes/start'),
        ),
      );

      await repository.startRoute();

      final captured = verify(
        () => dio.post<Map<String, dynamic>>(
          '/driver/routes/start',
          data: captureAny(named: 'data'),
          options: captureAny(named: 'options'),
        ),
      ).captured;

      expect(captured[0], equals(const <String, dynamic>{}));
    });
  });

  group('markAbsent', () {
    test('posts childId to the absent endpoint and falls back to absent stop',
        () async {
      when(
        () => dio.post<void>(
          '/driver/routes/42/absent',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<void>(
          statusCode: 200,
          requestOptions: RequestOptions(path: '/driver/routes/42/absent'),
        ),
      );
      when(
        () => dio.get<Map<String, dynamic>>('/driver/routes/active'),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: const <String, dynamic>{},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/driver/routes/active'),
        ),
      );

      final stop = await repository.markAbsent(42, 7);

      final captured = verify(
        () => dio.post<void>(
          '/driver/routes/42/absent',
          data: captureAny(named: 'data'),
          options: captureAny(named: 'options'),
        ),
      ).captured;

      expect(captured[0], equals(const {'childId': 7}));
      expect(stop.childId, 7);
      expect(stop.status, StopStatus.absent);
    });
  });

  group('removeStudent', () {
    test('posts childId to the remove-student endpoint', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/driver/routes/42/remove-student',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: const <String, dynamic>{},
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/driver/routes/42/remove-student',
          ),
        ),
      );

      await repository.removeStudent(42, 7);

      final captured = verify(
        () => dio.post<Map<String, dynamic>>(
          '/driver/routes/42/remove-student',
          data: captureAny(named: 'data'),
          options: captureAny(named: 'options'),
        ),
      ).captured;

      expect(captured[0], equals(const {'childId': 7}));
    });
  });
}
