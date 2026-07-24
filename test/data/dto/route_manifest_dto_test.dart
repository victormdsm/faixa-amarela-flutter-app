import 'package:app_faixa_amarela/data/dto/route_manifest_dto.dart';
import 'package:app_faixa_amarela/domain/models/route_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteManifestDto', () {
    test('fromJson parses real NestJS manifest contract', () {
      final json = <String, dynamic>{
        'id': 'manifest-uuid-123',
        'routeId': 1,
        'driverId': 5,
        'vanId': 2,
        'shiftId': 1,
        'startedAt': '2024-06-01T06:00:00.000Z',
        'status': 'active',
        'document': <String, dynamic>{
          'children': <Map<String, dynamic>>[
            <String, dynamic>{
              'childId': 10,
              'name': 'Ana Silva',
              'schoolId': 3,
              'schoolName': 'Escola Primavera',
              'address': <String, dynamic>{
                'id': 1001,
                'street': 'Rua das Flores',
                'number': '100',
                'latitude': -25.5,
                'longitude': -54.5,
              },
            },
            <String, dynamic>{
              'childId': 11,
              'name': 'Bruno Souza',
              'schoolId': 3,
              'schoolName': 'Escola Primavera',
              'address': <String, dynamic>{
                'id': 1002,
                'street': 'Rua do Sol',
                'number': '200',
                'latitude': -25.51,
                'longitude': -54.51,
              },
            },
          ],
        },
        'stops': [
          <String, dynamic>{
            'childId': 10,
            'order': 1,
            'type': 'pickup',
            'status': 'pending',
            'latitude': -25.5,
            'longitude': -54.5,
          },
          <String, dynamic>{
            'childId': 11,
            'order': 2,
            'type': 'pickup',
            'status': 'boarded',
            'latitude': -25.51,
            'longitude': -54.51,
            'boardedAt': '2024-06-01T06:15:00.000Z',
          },
        ],
      };

      final dto = RouteManifestDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.manifestId, 'manifest-uuid-123');
      expect(dto.driverId, 5);
      expect(dto.vanId, 2);
      expect(dto.shiftId, 1);
      expect(dto.status, RouteStatus.active);
      expect(dto.stops.length, 2);

      final first = dto.stops.first;
      expect(first.childId, 10);
      expect(first.childName, 'Ana Silva');
      expect(first.schoolName, 'Escola Primavera');
      expect(first.schoolId, 3);
      expect(first.address, 'Rua das Flores, 100');
      expect(first.sequence, 1);
      expect(first.status, StopStatus.pending);
      expect(first.latitude, -25.5);
      expect(first.longitude, -54.5);

      final second = dto.stops[1];
      expect(second.childId, 11);
      expect(second.childName, 'Bruno Souza');
      expect(second.status, StopStatus.boarded);
      expect(
        second.boardedAt,
        DateTime.parse('2024-06-01T06:15:00.000Z'),
      );
    });

    test('fromJson uses childLookup when provided', () {
      final json = <String, dynamic>{
        'id': 'manifest-uuid-456',
        'routeId': 2,
        'driverId': 6,
        'vanId': 3,
        'status': 'planning',
        'stops': [
          <String, dynamic>{
            'childId': 20,
            'order': 1,
            'type': 'pickup',
            'status': 'pending',
            'latitude': -25.6,
            'longitude': -54.6,
          },
        ],
      };

      final childLookup = <int, Map<String, dynamic>>{
        20: <String, dynamic>{
          'childId': 20,
          'name': 'Carlos Lima',
          'schoolId': 4,
          'schoolName': 'Escola Verao',
          'address': <String, dynamic>{
            'street': 'Av. Brasil',
            'number': '500',
            'latitude': -25.6,
            'longitude': -54.6,
          },
        },
      };

      final dto = RouteManifestDto.fromJson(
        json,
        childLookup: childLookup,
      );

      expect(dto.id, 2);
      expect(dto.stops.first.childName, 'Carlos Lima');
      expect(dto.stops.first.schoolName, 'Escola Verao');
      expect(dto.stops.first.address, 'Av. Brasil, 500');
    });

    test('toDomain maps correctly', () {
      final dto = RouteManifestDto(
        id: 1,
        manifestId: 'uuid',
        driverId: 5,
        vanId: 2,
        status: RouteStatus.planning,
        stops: [
          RouteStopDto(
            id: 0,
            childId: 10,
            childName: 'Ana Silva',
            schoolName: 'Escola Primavera',
            schoolId: 3,
            address: 'Rua das Flores, 100',
            sequence: 1,
            status: StopStatus.pending,
          ),
        ],
      );

      final domain = dto.toDomain();
      expect(domain, isA<RouteManifest>());
      expect(domain.stops.first.status, StopStatus.pending);
      expect(domain.stops.first.schoolName, 'Escola Primavera');
    });

    test('empty stops defaults to empty list', () {
      final json = <String, dynamic>{
        'id': 'manifest-uuid-789',
        'routeId': 3,
        'driverId': 5,
        'vanId': 2,
        'status': 'finished',
      };

      final dto = RouteManifestDto.fromJson(json);
      expect(dto.stops, isEmpty);
      expect(dto.id, 3);
      expect(dto.manifestId, 'manifest-uuid-789');
    });

    test('toJson serializes camelCase keys', () {
      final dto = RouteManifestDto(
        id: 1,
        manifestId: 'manifest-uuid',
        driverId: 5,
        vanId: 2,
        shiftId: 1,
        startedAt: DateTime.parse('2024-06-01T06:00:00.000Z'),
        finishedAt: DateTime.parse('2024-06-01T08:00:00.000Z'),
        status: RouteStatus.active,
        stops: [
          RouteStopDto(
            id: 10,
            childId: 20,
            childName: 'Ana Silva',
            schoolName: 'Escola Primavera',
            schoolId: 3,
            address: 'Rua das Flores, 100',
            sequence: 1,
            status: StopStatus.pending,
            latitude: -25.5,
            longitude: -54.5,
            boardedAt: DateTime.parse('2024-06-01T06:15:00.000Z'),
          ),
        ],
      );

      final json = dto.toJson();
      expect(json['id'], 1);
      expect(json['manifestId'], 'manifest-uuid');
      expect(json['driverId'], 5);
      expect(json['vanId'], 2);
      expect(json['shiftId'], 1);
      expect(json['startedAt'], '2024-06-01T06:00:00.000Z');
      expect(json['finishedAt'], '2024-06-01T08:00:00.000Z');
      expect(json['status'], 'active');

      final stopJson = (json['stops'] as List).first as Map<String, dynamic>;
      expect(stopJson['childId'], 20);
      expect(stopJson['childName'], 'Ana Silva');
      expect(stopJson['schoolName'], 'Escola Primavera');
      expect(stopJson['schoolId'], 3);
      expect(stopJson['address'], 'Rua das Flores, 100');
      expect(stopJson['sequence'], 1);
      expect(stopJson['status'], 'pending');
      expect(stopJson['latitude'], -25.5);
      expect(stopJson['longitude'], -54.5);
      expect(stopJson['boardedAt'], '2024-06-01T06:15:00.000Z');
    });
  });
}
