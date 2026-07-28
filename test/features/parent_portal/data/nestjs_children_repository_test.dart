import 'package:app_faixa_amarela/core/error/app_failure.dart';
import 'package:app_faixa_amarela/domain/models/child.dart';
import 'package:app_faixa_amarela/features/parent_portal/data/nestjs_children_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

DioException _notFound(String path, String message) {
  return DioException(
    requestOptions: RequestOptions(path: path),
    response: Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: path),
      statusCode: 404,
      data: {'message': message},
    ),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  late MockDio dio;
  late NestjsChildrenRepository repository;

  setUp(() {
    dio = MockDio();
    repository = NestjsChildrenRepository(dio);
  });

  group('autocompleteAddress', () {
    const payload = [
      <String, dynamic>{
        'label': 'Rua XV de Novembro, 100 - Centro, Curitiba/PR',
        'street': 'Rua XV de Novembro',
        'number': '100',
        'district': 'Centro',
        'city': 'Curitiba',
        'state': 'PR',
        'latitude': -25.43,
        'longitude': -49.27,
      },
      <String, dynamic>{
        'label': 'Rua XV de Novembro, 2000 - Centro, Curitiba/PR',
        'street': 'Rua XV de Novembro',
        'number': '2000',
        'district': 'Centro',
        'city': 'Curitiba',
        'state': 'PR',
        'latitude': -25.44,
        'longitude': -49.28,
      },
    ];

    test('parses suggestions and sends text + city params', () async {
      when(
        () => dio.get<dynamic>(
          '/parent/addresses/autocomplete',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          data: payload,
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/parent/addresses/autocomplete',
          ),
        ),
      );

      final result = await repository.autocompleteAddress(
        'Rua XV',
        city: 'Curitiba',
      );

      expect(result, hasLength(2));
      final first = result.first;
      expect(first.label, contains('Rua XV de Novembro'));
      expect(first.street, 'Rua XV de Novembro');
      expect(first.number, '100');
      expect(first.district, 'Centro');
      expect(first.city, 'Curitiba');
      expect(first.state, 'PR');
      expect(first.latitude, -25.43);
      expect(first.longitude, -49.27);

      final captured = verify(
        () => dio.get<dynamic>(
          '/parent/addresses/autocomplete',
          queryParameters: captureAny(named: 'queryParameters'),
        ),
      ).captured;
      final params = captured.single as Map<String, dynamic>;
      expect(params['text'], 'Rua XV');
      expect(params['city'], 'Curitiba');
    });

    test('omits the city param when not provided', () async {
      when(
        () => dio.get<dynamic>(
          '/parent/addresses/autocomplete',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          data: const <dynamic>[],
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/parent/addresses/autocomplete',
          ),
        ),
      );

      final result = await repository.autocompleteAddress('Rua XV');

      expect(result, isEmpty);
      final captured = verify(
        () => dio.get<dynamic>(
          '/parent/addresses/autocomplete',
          queryParameters: captureAny(named: 'queryParameters'),
        ),
      ).captured;
      final params = captured.single as Map<String, dynamic>;
      expect(params.containsKey('city'), isFalse);
    });

    test('tolerates the raw { data: [...] } envelope', () async {
      when(
        () => dio.get<dynamic>(
          '/parent/addresses/autocomplete',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          data: <String, dynamic>{'data': payload},
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/parent/addresses/autocomplete',
          ),
        ),
      );

      final result = await repository.autocompleteAddress('Rua XV');

      expect(result, hasLength(2));
    });
  });

  group('reverseAddress', () {
    test('parses the resolved address', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          '/parent/addresses/reverse',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: const <String, dynamic>{
            'label': 'Rua A, 10 - Centro, Curitiba/PR',
            'street': 'Rua A',
            'number': '10',
            'district': 'Centro',
            'city': 'Curitiba',
            'state': 'PR',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/parent/addresses/reverse'),
        ),
      );

      final result = await repository.reverseAddress(
        latitude: -25.43,
        longitude: -49.27,
      );

      expect(result.label, 'Rua A, 10 - Centro, Curitiba/PR');
      expect(result.street, 'Rua A');
      expect(result.number, '10');
      expect(result.district, 'Centro');
      expect(result.city, 'Curitiba');
      expect(result.state, 'PR');
      // O reverse não devolve coordenadas — o ponto consultado já é a origem.
      expect(result.latitude, isNull);
      expect(result.longitude, isNull);

      final captured = verify(
        () => dio.get<Map<String, dynamic>>(
          '/parent/addresses/reverse',
          queryParameters: captureAny(named: 'queryParameters'),
        ),
      ).captured;
      final params = captured.single as Map<String, dynamic>;
      expect(params['lat'], -25.43);
      expect(params['lon'], -49.27);
    });

    test('maps 404 to NotFoundFailure with the backend message', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          '/parent/addresses/reverse',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        _notFound(
          '/parent/addresses/reverse',
          'Não encontramos esse endereço.',
        ),
      );

      await expectLater(
        () => repository.reverseAddress(latitude: -25.4, longitude: -49.2),
        throwsA(
          isA<NotFoundFailure>().having(
            (f) => f.message,
            'message',
            'Não encontramos esse endereço.',
          ),
        ),
      );
    });
  });

  group('geocodeAddress', () {
    test('returns coordinates and label on success', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          '/parent/addresses/geocode',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: const <String, dynamic>{
            'latitude': -25.43,
            'longitude': -49.27,
            'label': 'Curitiba, PR',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/parent/addresses/geocode'),
        ),
      );

      final result = await repository.geocodeAddress('Curitiba, PR');

      expect(result, isNotNull);
      expect(result!.latitude, -25.43);
      expect(result.longitude, -49.27);
      expect(result.label, 'Curitiba, PR');
    });

    test('propagates 404 as NotFoundFailure (never swallows)', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          '/parent/addresses/geocode',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        _notFound(
          '/parent/addresses/geocode',
          'Não encontramos esse endereço.',
        ),
      );

      await expectLater(
        () => repository.geocodeAddress('endereço inexistente'),
        throwsA(
          isA<NotFoundFailure>().having(
            (f) => f.message,
            'message',
            'Não encontramos esse endereço.',
          ),
        ),
      );
    });
  });

  group('createChildAddress payload', () {
    test('includes city, state and neighborhood when present', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/parent/children/7/addresses',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: const <String, dynamic>{},
          statusCode: 201,
          requestOptions: RequestOptions(path: '/parent/children/7/addresses'),
        ),
      );

      await repository.createChildAddress(
        childId: 7,
        address: const ChildAddress(
          street: 'Rua X',
          number: '10',
          zipCode: '80000000',
          district: 'Centro',
          city: 'Curitiba',
          state: 'PR',
          latitude: -25.43,
          longitude: -49.27,
        ),
        isDefault: true,
      );

      final captured = verify(
        () => dio.post<Map<String, dynamic>>(
          '/parent/children/7/addresses',
          data: captureAny(named: 'data'),
        ),
      ).captured;
      final payload = captured.single as Map<String, dynamic>;
      expect(payload['street'], 'Rua X');
      expect(payload['number'], '10');
      expect(payload['zipcode'], '80000000');
      expect(payload['neighborhood'], 'Centro');
      expect(payload['city'], 'Curitiba');
      expect(payload['state'], 'PR');
      expect(payload['latitude'], -25.43);
      expect(payload['longitude'], -49.27);
      expect(payload['isDefault'], isTrue);
    });

    test('omits city, state and neighborhood when absent', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/parent/children/7/addresses',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: const <String, dynamic>{},
          statusCode: 201,
          requestOptions: RequestOptions(path: '/parent/children/7/addresses'),
        ),
      );

      await repository.createChildAddress(
        childId: 7,
        address: const ChildAddress(street: 'Rua X', number: '10'),
      );

      final captured = verify(
        () => dio.post<Map<String, dynamic>>(
          '/parent/children/7/addresses',
          data: captureAny(named: 'data'),
        ),
      ).captured;
      final payload = captured.single as Map<String, dynamic>;
      expect(payload.containsKey('neighborhood'), isFalse);
      expect(payload.containsKey('city'), isFalse);
      expect(payload.containsKey('state'), isFalse);
      expect(payload.containsKey('latitude'), isFalse);
      expect(payload.containsKey('longitude'), isFalse);
    });
  });
}
