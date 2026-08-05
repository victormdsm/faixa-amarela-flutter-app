import 'dart:convert';

import 'package:app_faixa_amarela/features/driver_portal/data/nestjs_driver_profile_change_request_repository.dart';
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
  late NestjsDriverProfileChangeRequestRepository repository;

  setUp(() {
    dio = MockDio();
    repository = NestjsDriverProfileChangeRequestRepository(dio);

    when(
      () => dio.post<Map<String, dynamic>>(
        '/driver/profile-change-requests',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => _jsonResponse('/driver/profile-change-requests', const {
        'id': 1,
        'status': 'pending',
      }),
    );
  });

  Map<String, dynamic> capturePayload() {
    final captured = verify(
      () => dio.post<Map<String, dynamic>>(
        '/driver/profile-change-requests',
        data: captureAny(named: 'data'),
      ),
    ).captured;
    return Map<String, dynamic>.from(captured.single as Map);
  }

  group('submitRequest vehicle fields', () {
    test('includes the 4 vehicle fields when provided', () async {
      await repository.submitRequest(
        schoolIds: const [1, 2],
        districtIds: const [10],
        schoolShiftMap: const {
          1: [1, 2],
        },
        districtShiftMap: null,
        vehicleId: 7,
        requestedVehiclePlaca: 'ABC1D23',
        requestedVehicleMarca: 'Fiat Ducato',
        requestedVehicleCor: 'Branca',
        requestedVehicleAno: '2020',
      );

      final payload = capturePayload();
      expect(payload['requestedVehiclePlaca'], 'ABC1D23');
      expect(payload['requestedVehicleMarca'], 'Fiat Ducato');
      expect(payload['requestedVehicleCor'], 'Branca');
      expect(payload['requestedVehicleAno'], '2020');
      // Campos já existentes continuam intactos.
      expect(payload['vehicleId'], 7);
      expect(jsonDecode(payload['requestedSchoolIds'] as String), [1, 2]);
      expect(jsonDecode(payload['requestedDistrictIds'] as String), [10]);
      expect(
        jsonDecode(payload['requestedSchoolShiftMap'] as String),
        [
          {
            'schoolId': 1,
            'shiftIds': [1, 2],
          },
        ],
      );
    });

    test('omits the vehicle fields when not provided', () async {
      await repository.submitRequest(
        schoolIds: const [1],
        districtIds: const [10],
        schoolShiftMap: const {
          1: [1],
        },
        districtShiftMap: null,
      );

      final payload = capturePayload();
      expect(payload.containsKey('requestedVehiclePlaca'), isFalse);
      expect(payload.containsKey('requestedVehicleMarca'), isFalse);
      expect(payload.containsKey('requestedVehicleCor'), isFalse);
      expect(payload.containsKey('requestedVehicleAno'), isFalse);
    });

    test('omits only the vehicle fields left null', () async {
      await repository.submitRequest(
        schoolIds: const [1],
        districtIds: const [10],
        schoolShiftMap: const {
          1: [1],
        },
        districtShiftMap: null,
        requestedVehiclePlaca: 'ABC1234',
        requestedVehicleAno: '2021',
      );

      final payload = capturePayload();
      expect(payload['requestedVehiclePlaca'], 'ABC1234');
      expect(payload['requestedVehicleAno'], '2021');
      expect(payload.containsKey('requestedVehicleMarca'), isFalse);
      expect(payload.containsKey('requestedVehicleCor'), isFalse);
    });
  });

  group('submitRequest contato público (aprovação)', () {
    test('includes the 2 fields when provided', () async {
      await repository.submitRequest(
        schoolIds: const [1],
        districtIds: const [10],
        schoolShiftMap: const {
          1: [1],
        },
        districtShiftMap: null,
        requestedPublicContactName: 'Van Escolar do Carlos',
        requestedPublicContactPhone: '45988887777',
      );

      final payload = capturePayload();
      expect(payload['requestedPublicContactName'], 'Van Escolar do Carlos');
      expect(payload['requestedPublicContactPhone'], '45988887777');
    });

    test('omits the 2 fields when not provided', () async {
      await repository.submitRequest(
        schoolIds: const [1],
        districtIds: const [10],
        schoolShiftMap: const {
          1: [1],
        },
        districtShiftMap: null,
      );

      final payload = capturePayload();
      expect(payload.containsKey('requestedPublicContactName'), isFalse);
      expect(payload.containsKey('requestedPublicContactPhone'), isFalse);
      expect(payload.containsKey('requestedDescription'), isFalse);
    });
  });

  group('submitRequest cobertura (schoolShiftMap e districtShiftMap)', () {
    test(
      'omits coverage maps when the driver did not edit coverage',
      () async {
        await repository.submitRequest(
          schoolIds: const [1, 2],
          districtIds: null,
          schoolShiftMap: null,
          districtShiftMap: null,
          avatarImagePath: 'https://cdn.example.com/avatar.jpg',
        );

        final payload = capturePayload();
        expect(payload.containsKey('requestedDistrictIds'), isFalse);
        expect(payload.containsKey('requestedSchoolShiftMap'), isFalse);
        expect(payload.containsKey('requestedDistrictShiftMap'), isFalse);
        // Escolas e foto seguem no payload normalmente.
        expect(jsonDecode(payload['requestedSchoolIds'] as String), [1, 2]);
        expect(
          payload['requestedAvatarPath'],
          'https://cdn.example.com/avatar.jpg',
        );
      },
    );

    test(
      'sends requestedDistrictIds, requestedSchoolShiftMap and requestedDistrictShiftMap when the driver edited coverage',
      () async {
        await repository.submitRequest(
          schoolIds: const [1, 3],
          districtIds: const [10, 20],
          schoolShiftMap: const {
            1: [1, 3],
            3: [2],
          },
          districtShiftMap: const {
            10: [1, 2],
            20: [2],
          },
        );

        final payload = capturePayload();
        expect(jsonDecode(payload['requestedSchoolIds'] as String), [1, 3]);
        expect(jsonDecode(payload['requestedDistrictIds'] as String), [10, 20]);
        expect(
          jsonDecode(payload['requestedSchoolShiftMap'] as String),
          [
            {
              'schoolId': 1,
              'shiftIds': [1, 3],
            },
            {
              'schoolId': 3,
              'shiftIds': [2],
            },
          ],
        );
        expect(
          jsonDecode(payload['requestedDistrictShiftMap'] as String),
          [
            {
              'districtId': 10,
              'shiftIds': [1, 2],
            },
            {
              'districtId': 20,
              'shiftIds': [2],
            },
          ],
        );
      },
    );
  });
}
