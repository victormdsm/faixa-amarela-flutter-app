import 'package:app_faixa_amarela/data/dto/enrollment_dto.dart';
import 'package:app_faixa_amarela/domain/models/enrollment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnrollmentDto', () {
    test('fromJson parses pending status', () {
      final json = <String, dynamic>{
        'id': 1,
        'childId': 10,
        'childName': 'Ana Silva',
        'driverUserId': 5,
        'driverName': 'José Motorista',
        'vanPlate': 'ABC1234',
        'schoolName': 'Escola Primavera',
        'status': 'pending',
        'requestedAt': '2024-06-01T10:00:00.000Z',
      };

      final dto = EnrollmentDto.fromJson(json);
      expect(dto.id, 1);
      expect(dto.childName, 'Ana Silva');
      expect(dto.status, EnrollmentStatus.pending);
      expect(dto.requestedAt, DateTime.parse('2024-06-01T10:00:00.000Z'));
    });

    test('driverId maps from driverUserId', () {
      final json = <String, dynamic>{
        'id': 1,
        'childId': 10,
        'childName': 'Ana Silva',
        'driverUserId': 55,
        'driverName': 'José Motorista',
        'vanPlate': 'ABC1234',
        'schoolName': 'Escola Primavera',
        'status': 'pending',
      };

      final dto = EnrollmentDto.fromJson(json);
      expect(dto.driverId, 55);
    });

    test('respondedAt maps from acceptedAt fallback', () {
      final json = <String, dynamic>{
        'id': 1,
        'childId': 10,
        'childName': 'Ana Silva',
        'driverUserId': 5,
        'driverName': 'José Motorista',
        'vanPlate': 'ABC1234',
        'schoolName': 'Escola Primavera',
        'status': 'active',
        'acceptedAt': '2024-06-01T11:00:00.000Z',
      };

      final dto = EnrollmentDto.fromJson(json);
      expect(dto.respondedAt, DateTime.parse('2024-06-01T11:00:00.000Z'));
    });

    test('toDomain maps to Enrollment', () {
      final dto = EnrollmentDto(
        id: 1,
        childId: 10,
        childName: 'Ana Silva',
        driverId: 5,
        driverName: 'José Motorista',
        vanPlate: 'ABC1234',
        schoolName: 'Escola Primavera',
        status: EnrollmentStatus.active,
      );

      final domain = dto.toDomain();
      expect(domain, isA<Enrollment>());
      expect(domain.status, EnrollmentStatus.active);
    });

    test('toJson serializes camelCase keys', () {
      final dto = EnrollmentDto(
        id: 1,
        childId: 10,
        childName: 'Ana Silva',
        driverId: 5,
        driverName: 'José Motorista',
        vanPlate: 'ABC1234',
        schoolName: 'Escola Primavera',
        status: EnrollmentStatus.active,
        requestedAt: DateTime.parse('2024-06-01T10:00:00.000Z'),
        respondedAt: DateTime.parse('2024-06-01T11:00:00.000Z'),
      );

      final json = dto.toJson();
      expect(json['id'], 1);
      expect(json['childId'], 10);
      expect(json['driverId'], 5);
      expect(json['driverName'], 'José Motorista');
      expect(json['vanPlate'], 'ABC1234');
      expect(json['schoolName'], 'Escola Primavera');
      expect(json['status'], 'active');
      expect(json['requestedAt'], '2024-06-01T10:00:00.000Z');
      expect(json['respondedAt'], '2024-06-01T11:00:00.000Z');
    });

    test('fromDomain roundtrip', () {
      final enrollment = Enrollment(
        id: 1,
        childId: 10,
        childName: 'Ana Silva',
        driverId: 5,
        driverName: 'José Motorista',
        vanPlate: 'ABC1234',
        schoolName: 'Escola Primavera',
        status: EnrollmentStatus.rejected,
        requestedAt: DateTime.parse('2024-06-01T10:00:00.000Z'),
      );

      final dto = EnrollmentDto.fromDomain(enrollment);
      expect(dto.status, EnrollmentStatus.rejected);
      expect(dto.requestedAt, enrollment.requestedAt);
    });
  });
}
