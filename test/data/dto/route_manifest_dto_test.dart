import 'package:app_faixa_amarela/data/dto/route_manifest_dto.dart';
import 'package:app_faixa_amarela/domain/models/route_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteManifestDto', () {
    test('fromJson parses route with stops', () {
      final json = <String, dynamic>{
        'id': 1,
        'driver_id': 5,
        'van_id': 2,
        'started_at': '2024-06-01T06:00:00.000Z',
        'status': 'active',
        'stops': [
          <String, dynamic>{
            'id': 101,
            'child_id': 10,
            'child_name': 'Ana Silva',
            'school_name': 'Escola Primavera',
            'address': 'Rua das Flores, 100',
            'sequence': 1,
            'status': 'pending',
          },
          <String, dynamic>{
            'id': 102,
            'child_id': 11,
            'child_name': 'Bruno Souza',
            'school_name': 'Escola Primavera',
            'address': 'Rua do Sol, 200',
            'sequence': 2,
            'status': 'boarded',
            'boarded_at': '2024-06-01T06:15:00.000Z',
          },
        ],
      };

      final dto = RouteManifestDto.fromJson(json);
      expect(dto.id, 1);
      expect(dto.status, RouteStatus.active);
      expect(dto.stops.length, 2);
      expect(dto.stops.first.childName, 'Ana Silva');
      expect(dto.stops.first.status, StopStatus.pending);
      expect(dto.stops[1].status, StopStatus.boarded);
      expect(
        dto.stops[1].boardedAt,
        DateTime.parse('2024-06-01T06:15:00.000Z'),
      );
    });

    test('toDomain maps correctly', () {
      final dto = RouteManifestDto(
        id: 1,
        driverId: 5,
        vanId: 2,
        status: RouteStatus.planning,
        stops: [
          RouteStopDto(
            id: 101,
            childId: 10,
            childName: 'Ana Silva',
            schoolName: 'Escola Primavera',
            address: 'Rua das Flores, 100',
            sequence: 1,
            status: StopStatus.pending,
          ),
        ],
      );

      final domain = dto.toDomain();
      expect(domain, isA<RouteManifest>());
      expect(domain.stops.first.status, StopStatus.pending);
    });

    test('empty stops defaults to empty list', () {
      final json = <String, dynamic>{
        'id': 1,
        'driver_id': 5,
        'van_id': 2,
        'status': 'finished',
      };

      final dto = RouteManifestDto.fromJson(json);
      expect(dto.stops, isEmpty);
    });
  });
}
