import 'package:app_faixa_amarela/data/dto/enrollment_dto.dart';
import 'package:app_faixa_amarela/domain/models/enrollment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnrollmentDto', () {
    test('fromJson parses pending status', () {
      final json = <String, dynamic>{
        'id': 1,
        'child_id': 10,
        'child_name': 'Ana Silva',
        'driver_id': 5,
        'driver_name': 'José Motorista',
        'van_plate': 'ABC1234',
        'school_name': 'Escola Primavera',
        'status': 'pending',
        'requested_at': '2024-06-01T10:00:00.000Z',
      };

      final dto = EnrollmentDto.fromJson(json);
      expect(dto.id, 1);
      expect(dto.childName, 'Ana Silva');
      expect(dto.status, EnrollmentStatus.pending);
      expect(dto.requestedAt, DateTime.parse('2024-06-01T10:00:00.000Z'));
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
