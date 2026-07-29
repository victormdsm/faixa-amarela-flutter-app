import 'package:app_faixa_amarela/core/network/api_exception.dart';
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

  group('updateMyVehicle', () {
    test('sends placa plus only the edited fields', () async {
      when(
        () => dio.put<Map<String, dynamic>>(
          '/drivers/me/vehicle',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => _jsonResponse('/drivers/me/vehicle', const {'id': 7}),
      );

      await repository.updateMyVehicle(
        plate: 'ABC1234',
        brand: 'Fiat Ducato',
      );

      final captured = verify(
        () => dio.put<Map<String, dynamic>>(
          '/drivers/me/vehicle',
          data: captureAny(named: 'data'),
        ),
      ).captured;

      // Apenas placa (obrigatoria) + marca (editada); cor/ano omitidos.
      expect(
        captured[0],
        equals(const <String, dynamic>{
          'placa': 'ABC1234',
          'marca': 'Fiat Ducato',
        }),
      );
    });

    test('always includes placa, even when it is the only field', () async {
      when(
        () => dio.put<Map<String, dynamic>>(
          '/drivers/me/vehicle',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => _jsonResponse('/drivers/me/vehicle', const {'id': 7}),
      );

      await repository.updateMyVehicle(plate: 'ABC1D23');

      final captured = verify(
        () => dio.put<Map<String, dynamic>>(
          '/drivers/me/vehicle',
          data: captureAny(named: 'data'),
        ),
      ).captured;

      expect(captured[0], equals(const <String, dynamic>{'placa': 'ABC1D23'}));
    });

    test('sends every field when all were edited', () async {
      when(
        () => dio.put<Map<String, dynamic>>(
          '/drivers/me/vehicle',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => _jsonResponse('/drivers/me/vehicle', const {'id': 7}),
      );

      await repository.updateMyVehicle(
        plate: 'ABC1234',
        brand: 'Fiat Ducato',
        color: 'Branca',
        year: '2020',
      );

      final captured = verify(
        () => dio.put<Map<String, dynamic>>(
          '/drivers/me/vehicle',
          data: captureAny(named: 'data'),
        ),
      ).captured;

      expect(
        captured[0],
        equals(const <String, dynamic>{
          'placa': 'ABC1234',
          'marca': 'Fiat Ducato',
          'cor': 'Branca',
          'ano': '2020',
        }),
      );
    });

    test('wraps dio errors in ApiException', () async {
      when(
        () => dio.put<Map<String, dynamic>>(
          '/drivers/me/vehicle',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/drivers/me/vehicle'),
        ),
      );

      expect(
        () => repository.updateMyVehicle(plate: 'ABC1234'),
        throwsA(isA<ApiException>()),
      );
    });
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

    test('never sends an empty cnh (would clobber the stored value)',
        () async {
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
      expect(payload.containsKey('cnh'), isFalse);
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
