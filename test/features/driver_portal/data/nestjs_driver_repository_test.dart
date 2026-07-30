import 'package:app_faixa_amarela/domain/models/driver_profile.dart';
import 'package:app_faixa_amarela/features/driver_portal/data/nestjs_driver_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

Response<Map<String, dynamic>> _jsonResponse(
  String path,
  Map<String, dynamic> data,
) {
  return Response<Map<String, dynamic>>(
    data: data,
    statusCode: 200,
    requestOptions: RequestOptions(path: path),
  );
}

void main() {
  late MockDio dio;
  late NestjsDriverRepository repository;

  setUp(() {
    dio = MockDio();
    repository = NestjsDriverRepository(dio);
  });

  group('updateBasicProfile cnh handling', () {
    setUp(() {
      when(
        () => dio.put<Map<String, dynamic>>(
          '/drivers/me',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => _jsonResponse('/drivers/me', const {}));
      when(
        () => dio.get<Map<String, dynamic>>('/drivers/me'),
      ).thenAnswer((_) async => _jsonResponse('/drivers/me', const {}));
      when(
        () => dio.put<Map<String, dynamic>>(
          '/users/me',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => _jsonResponse('/users/me', const {}));
    });

    test('omits cnh when it was not edited (null)', () async {
      await repository.updateBasicProfile(
        name: 'Joao',
        information: 'Van adaptada',
        cnh: null,
      );

      final captured = verify(
        () => dio.put<Map<String, dynamic>>(
          '/drivers/me',
          data: captureAny(named: 'data'),
        ),
      ).captured;

      final payload = captured[0] as Map<String, dynamic>;
      expect(payload.containsKey('cnh'), isFalse);
      expect(payload['information'], 'Van adaptada');
    });

    test('includes cnh when it was edited', () async {
      await repository.updateBasicProfile(
        name: 'Joao',
        information: 'Van adaptada',
        cnh: '98765432100',
      );

      final captured = verify(
        () => dio.put<Map<String, dynamic>>(
          '/drivers/me',
          data: captureAny(named: 'data'),
        ),
      ).captured;

      final payload = captured[0] as Map<String, dynamic>;
      expect(payload['cnh'], '98765432100');
    });

    test('sends cnh as empty string when the driver cleared the field '
        '(APP-11: backend accepts \'\' as clear)', () async {
      await repository.updateBasicProfile(
        name: 'Joao',
        information: 'Van adaptada',
        cnh: '',
      );

      final captured = verify(
        () => dio.put<Map<String, dynamic>>(
          '/drivers/me',
          data: captureAny(named: 'data'),
        ),
      ).captured;

      final payload = captured[0] as Map<String, dynamic>;
      expect(payload['cnh'], '');
    });

    test('does not touch PUT /drivers/me when nothing changed', () async {
      await repository.updateBasicProfile(name: 'Joao');

      verifyNever(
        () => dio.put<Map<String, dynamic>>(
          '/drivers/me',
          data: any(named: 'data'),
        ),
      );
      verify(() => dio.get<Map<String, dynamic>>('/drivers/me')).called(1);
    });
  });

  group('DriverProfile.normalizeVanId', () {
    test('coerces missing or non-positive ids to null', () {
      expect(DriverProfile.normalizeVanId(null), isNull);
      expect(DriverProfile.normalizeVanId(0), isNull);
      expect(DriverProfile.normalizeVanId(-3), isNull);
    });

    test('keeps valid ids', () {
      expect(DriverProfile.normalizeVanId(7), 7);
      expect(DriverProfile.normalizeVanId(1), 1);
    });
  });
}
