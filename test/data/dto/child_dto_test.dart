import 'package:app_faixa_amarela/data/dto/child_dto.dart';
import 'package:app_faixa_amarela/domain/models/child.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChildDto', () {
    test('fromJson parses NestJS camelCase contract', () {
      final json = <String, dynamic>{
        'id': 1,
        'name': 'Ana Silva',
        'cpf': '12345678901',
        'schoolId': 7,
        'shiftId': 2,
        'isInadimplent': true,
        'createdAt': '2024-01-01T00:00:00.000Z',
      };

      final dto = ChildDto.fromJson(json);
      expect(dto.id, 1);
      expect(dto.name, 'Ana Silva');
      expect(dto.cpf, '12345678901');
      expect(dto.schoolId, 7);
      expect(dto.shiftId, 2);
      expect(dto.isInDebt, true);
      expect(dto.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
    });

    test('fromJson parses internal camelCase keys', () {
      final json = <String, dynamic>{
        'id': 2,
        'name': 'Bruno Souza',
        'cpf': '98765432100',
        'schoolId': 3,
        'shiftId': 1,
        'isInDebt': 1,
        'createdAt': '2024-06-15T10:30:00.000Z',
      };

      final dto = ChildDto.fromJson(json);
      expect(dto.id, 2);
      expect(dto.schoolId, 3);
      expect(dto.shiftId, 1);
      expect(dto.isInDebt, true);
      expect(dto.createdAt, DateTime.parse('2024-06-15T10:30:00.000Z'));
    });

    test('toJson serializes camelCase keys', () {
      final dto = ChildDto(
        id: 1,
        name: 'Ana Silva',
        cpf: '12345678901',
        schoolId: 7,
        shiftId: 2,
        isInDebt: true,
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final json = dto.toJson();
      expect(json['id'], 1);
      expect(json['name'], 'Ana Silva');
      expect(json['cpf'], '12345678901');
      expect(json['schoolId'], 7);
      expect(json['shiftId'], 2);
      expect(json['isInDebt'], true);
      expect(json['createdAt'], '2024-01-01T00:00:00.000Z');
    });

    test('toDomain maps correctly', () {
      final dto = ChildDto(
        id: 1,
        name: 'Ana Silva',
        cpf: '12345678901',
        schoolId: 7,
        shiftId: 2,
        isInDebt: true,
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final domain = dto.toDomain();
      expect(domain, isA<Child>());
      expect(domain.id, 1);
      expect(domain.name, 'Ana Silva');
      expect(domain.cpf, '12345678901');
      expect(domain.schoolId, 7);
      expect(domain.shiftId, 2);
      expect(domain.isInDebt, true);
      expect(domain.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
    });

    test('fromDomain maps correctly', () {
      final child = Child(
        id: 1,
        name: 'Ana Silva',
        cpf: '12345678901',
        schoolId: 7,
        shiftId: 2,
        isInDebt: true,
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final dto = ChildDto.fromDomain(child);
      expect(dto.name, 'Ana Silva');
      expect(dto.schoolId, 7);
      expect(dto.shiftId, 2);
      expect(dto.isInDebt, true);
    });
  });
}
