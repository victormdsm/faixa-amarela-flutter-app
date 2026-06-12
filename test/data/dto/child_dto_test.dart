import 'package:app_faixa_amarela/data/dto/child_dto.dart';
import 'package:app_faixa_amarela/domain/models/child.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChildDto', () {
    test('fromJson parses correctly', () {
      final json = <String, dynamic>{
        'id': 1,
        'name': 'Ana Silva',
        'cpf': '12345678901',
        'birth_date': '2015-03-10T00:00:00.000Z',
        'school_name': 'Escola Primavera',
        'shift_id': 2,
        'shift_name': 'Manhã',
        'parent_id': 10,
        'parent_name': 'Maria Silva',
        'address': <String, dynamic>{
          'street': 'Rua das Flores',
          'number': '100',
          'complement': 'Apto 2',
          'neighborhood': 'Jardim',
          'city': 'São Paulo',
          'state': 'SP',
          'zip_code': '01001000',
          'latitude': -23.55,
          'longitude': -46.63,
        },
        'photo_url': 'https://example.com/photo.jpg',
        'is_in_debt': true,
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      final dto = ChildDto.fromJson(json);
      expect(dto.id, 1);
      expect(dto.name, 'Ana Silva');
      expect(dto.cpf, '12345678901');
      expect(dto.birthDate, DateTime.parse('2015-03-10T00:00:00.000Z'));
      expect(dto.schoolName, 'Escola Primavera');
      expect(dto.shiftId, 2);
      expect(dto.shiftName, 'Manhã');
      expect(dto.parentId, 10);
      expect(dto.parentName, 'Maria Silva');
      expect(dto.address.street, 'Rua das Flores');
      expect(dto.address.latitude, -23.55);
      expect(dto.photoUrl, 'https://example.com/photo.jpg');
      expect(dto.isInDebt, true);
      expect(dto.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
    });

    test('toJson serializes correctly', () {
      final dto = ChildDto(
        id: 1,
        name: 'Ana Silva',
        cpf: '12345678901',
        birthDate: DateTime.parse('2015-03-10T00:00:00.000Z'),
        schoolName: 'Escola Primavera',
        shiftId: 2,
        shiftName: 'Manhã',
        parentId: 10,
        parentName: 'Maria Silva',
        address: ChildAddressDto(
          street: 'Rua das Flores',
          number: '100',
          complement: 'Apto 2',
          neighborhood: 'Jardim',
          city: 'São Paulo',
          state: 'SP',
          zipCode: '01001000',
          latitude: -23.55,
          longitude: -46.63,
        ),
        photoUrl: 'https://example.com/photo.jpg',
        isInDebt: true,
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final json = dto.toJson();
      expect(json['id'], 1);
      expect(json['name'], 'Ana Silva');
      expect(json['cpf'], '12345678901');
      expect(json['school_name'], 'Escola Primavera');
      expect(json['address'], isA<Map<String, dynamic>>());
    });

    test('toDomain maps correctly', () {
      final dto = ChildDto(
        id: 1,
        name: 'Ana Silva',
        cpf: '12345678901',
        birthDate: DateTime.parse('2015-03-10T00:00:00.000Z'),
        schoolName: 'Escola Primavera',
        shiftId: 2,
        shiftName: 'Manhã',
        parentId: 10,
        parentName: 'Maria Silva',
        address: ChildAddressDto(
          street: 'Rua das Flores',
          number: '100',
          neighborhood: 'Jardim',
          city: 'São Paulo',
          state: 'SP',
          zipCode: '01001000',
        ),
        isInDebt: false,
      );

      final domain = dto.toDomain();
      expect(domain, isA<Child>());
      expect(domain.name, 'Ana Silva');
      expect(domain.address.street, 'Rua das Flores');
    });

    test('fromDomain maps correctly', () {
      final child = Child(
        id: 1,
        name: 'Ana Silva',
        cpf: '12345678901',
        birthDate: DateTime.parse('2015-03-10T00:00:00.000Z'),
        schoolName: 'Escola Primavera',
        shiftId: 2,
        shiftName: 'Manhã',
        parentId: 10,
        parentName: 'Maria Silva',
        address: ChildAddress(
          street: 'Rua das Flores',
          number: '100',
          neighborhood: 'Jardim',
          city: 'São Paulo',
          state: 'SP',
          zipCode: '01001000',
        ),
      );

      final dto = ChildDto.fromDomain(child);
      expect(dto.name, 'Ana Silva');
      expect(dto.address.city, 'São Paulo');
    });
  });
}
