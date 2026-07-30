import 'package:app_faixa_amarela/data/dto/driver_profile_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DriverProfileDto coverage.districtShiftMap (APP-02)', () {
    Map<String, dynamic> baseJson({dynamic districtShiftMap}) {
      return <String, dynamic>{
        'id': 1,
        'userId': 10,
        'name': 'Tio Joao',
        'coverage': <String, dynamic>{
          'schools': [1, 2],
          'districts': [10, 20],
          'shifts': [1, 2],
          'districtShiftMap': ?districtShiftMap,
        },
      };
    }

    List<int> shiftIdsOf(Map<String, dynamic> district) =>
        (district['shiftIds'] as List).cast<int>();

    test('usa o mapa real bairro→turnos quando o backend o envia (objeto)', () {
      final dto = DriverProfileDto.fromJson(
        baseJson(
          districtShiftMap: <String, dynamic>{
            '10': [1, 2],
            '20': [2],
          },
        ),
      );

      expect(dto.districtShiftMap, {
        10: [1, 2],
        20: [2],
      });
      expect(dto.districts, hasLength(2));
      expect(shiftIdsOf(dto.districts[0]), [1, 2]);
      expect(shiftIdsOf(dto.districts[1]), [2]);
    });

    test('tolera o mapa serializado como lista de {districtId, shiftIds}', () {
      final dto = DriverProfileDto.fromJson(
        baseJson(
          districtShiftMap: [
            <String, dynamic>{
              'districtId': 10,
              'shiftIds': [1, 2],
            },
            <String, dynamic>{
              'districtId': 20,
              'shiftIds': [3],
            },
          ],
        ),
      );

      expect(dto.districtShiftMap, {
        10: [1, 2],
        20: [3],
      });
      expect(shiftIdsOf(dto.districts[0]), [1, 2]);
      expect(shiftIdsOf(dto.districts[1]), [3]);
    });

    test('sem districtShiftMap NÃO fabrica a união de turnos por bairro', () {
      final dto = DriverProfileDto.fromJson(baseJson());

      expect(dto.districtShiftMap, isEmpty);
      expect(dto.districts, hasLength(2));
      // Antes do APP-02 cada bairro recebia [1, 2] (união global replicada).
      expect(shiftIdsOf(dto.districts[0]), isEmpty);
      expect(shiftIdsOf(dto.districts[1]), isEmpty);
    });

    test('bairro fora do mapa fica sem turnos (demais seguem o mapa)', () {
      final dto = DriverProfileDto.fromJson(
        baseJson(
          districtShiftMap: <String, dynamic>{
            '10': [1],
          },
        ),
      );

      expect(shiftIdsOf(dto.districts[0]), [1]);
      expect(shiftIdsOf(dto.districts[1]), isEmpty);
    });

    test('districts legados (cache) têm precedência sobre o mapa', () {
      final json = baseJson(
        districtShiftMap: <String, dynamic>{
          '10': [1],
        },
      );
      json['districts'] = [
        <String, dynamic>{
          'id': 10,
          'shiftIds': [1, 2, 3],
        },
      ];

      final dto = DriverProfileDto.fromJson(json);

      expect(dto.districts, hasLength(1));
      expect(shiftIdsOf(dto.districts[0]), [1, 2, 3]);
    });
  });
}
