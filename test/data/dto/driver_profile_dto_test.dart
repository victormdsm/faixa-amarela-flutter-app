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

  group('DriverProfileDto coverage.schoolShiftMap', () {
    Map<String, dynamic> baseJson({dynamic schoolShiftMap}) {
      return <String, dynamic>{
        'id': 1,
        'userId': 10,
        'name': 'Tio Joao',
        'coverage': <String, dynamic>{
          'schools': [1, 2],
          'districts': [10, 20],
          'shifts': [1, 2],
          'schoolShiftMap': ?schoolShiftMap,
        },
      };
    }

    List<int> schoolShiftIdsOf(Map<String, dynamic> school) =>
        (school['shiftIds'] as List).cast<int>();

    test('usa o mapa real escola→turnos quando o backend o envia (objeto)', () {
      final dto = DriverProfileDto.fromJson(
        baseJson(
          schoolShiftMap: <String, dynamic>{
            '1': [1, 2],
            '2': [2],
          },
        ),
      );

      expect(dto.schoolShiftMap, {
        1: [1, 2],
        2: [2],
      });
      expect(dto.schools, hasLength(2));
      expect(schoolShiftIdsOf(dto.schools[0]), [1, 2]);
      expect(schoolShiftIdsOf(dto.schools[1]), [2]);
    });

    test('tolera o mapa serializado como lista de {schoolId, shiftIds}', () {
      final dto = DriverProfileDto.fromJson(
        baseJson(
          schoolShiftMap: [
            <String, dynamic>{
              'schoolId': 1,
              'shiftIds': [1, 2],
            },
            <String, dynamic>{
              'schoolId': 2,
              'shiftIds': [3],
            },
          ],
        ),
      );

      expect(dto.schoolShiftMap, {
        1: [1, 2],
        2: [3],
      });
      expect(schoolShiftIdsOf(dto.schools[0]), [1, 2]);
      expect(schoolShiftIdsOf(dto.schools[1]), [3]);
    });

    test('sem schoolShiftMap as escolas ficam sem turnos (nada de fabricar)', () {
      final dto = DriverProfileDto.fromJson(baseJson());

      expect(dto.schoolShiftMap, isEmpty);
      expect(dto.schools, hasLength(2));
      expect(schoolShiftIdsOf(dto.schools[0]), isEmpty);
      expect(schoolShiftIdsOf(dto.schools[1]), isEmpty);
    });

    test('escola fora do mapa fica sem turnos (demais seguem o mapa)', () {
      final dto = DriverProfileDto.fromJson(
        baseJson(
          schoolShiftMap: <String, dynamic>{
            '1': [1],
          },
        ),
      );

      expect(schoolShiftIdsOf(dto.schools[0]), [1]);
      expect(schoolShiftIdsOf(dto.schools[1]), isEmpty);
    });

    test('schools legadas (cache) têm precedência sobre o mapa', () {
      final json = baseJson(
        schoolShiftMap: <String, dynamic>{
          '1': [1],
        },
      );
      json['schools'] = [
        <String, dynamic>{
          'id': 1,
          'shiftIds': [1, 2, 3],
        },
      ];

      final dto = DriverProfileDto.fromJson(json);

      expect(dto.schools, hasLength(1));
      expect(schoolShiftIdsOf(dto.schools[0]), [1, 2, 3]);
    });
  });

  group('DriverProfileDto coverage.schools (maps reais do NestJS)', () {
    Map<String, dynamic> baseJson({
      dynamic schools,
      dynamic schoolShiftMap,
      dynamic districtShiftMap,
    }) {
      return <String, dynamic>{
        'id': 1,
        'userId': 10,
        'name': 'Tio Joao',
        'coverage': <String, dynamic>{
          'schools': schools,
          'districts': [59, 178],
          'shifts': [1, 2, 3, 4],
          'schoolShiftMap': schoolShiftMap,
          'districtShiftMap': districtShiftMap,
        },
      };
    }

    List<int> schoolShiftIdsOf(Map<String, dynamic> school) =>
        (school['shiftIds'] as List).cast<int>();

    test(
        'parseia payload real de produção (schools como maps com '
        'schoolId/name/shiftIds)', () {
      final dto = DriverProfileDto.fromJson(
        baseJson(
          schools: [
            <String, dynamic>{
              'schoolId': 307,
              'name': 'APAE Melvin Jones Unidade I',
              'shiftIds': [4],
            },
            <String, dynamic>{
              'schoolId': 275,
              'name': 'APMI',
              'shiftIds': [2],
            },
          ],
          schoolShiftMap: <String, dynamic>{
            '136': [2],
            '229': [1],
            '307': [1, 3],
          },
          districtShiftMap: <String, dynamic>{
            '59': [1, 3, 4],
            '178': [2, 4],
          },
        ),
      );

      expect(dto.schools, hasLength(2));
      expect(dto.schools[0]['id'], 307);
      expect(dto.schools[0]['name'], 'APAE Melvin Jones Unidade I');
      expect(schoolShiftIdsOf(dto.schools[0]), [4]);
      expect(dto.schools[1]['id'], 275);
      expect(dto.schools[1]['name'], 'APMI');
      expect(schoolShiftIdsOf(dto.schools[1]), [2]);
      expect(dto.districtShiftMap, {
        59: [1, 3, 4],
        178: [2, 4],
      });
    });

    test('escola sem shiftIds cai no schoolShiftMap[id]', () {
      final dto = DriverProfileDto.fromJson(
        baseJson(
          schools: [
            <String, dynamic>{
              'schoolId': 136,
              'name': 'Escola sem turnos no item',
            },
          ],
          schoolShiftMap: <String, dynamic>{
            '136': [2, 3],
          },
        ),
      );

      expect(dto.schools, hasLength(1));
      expect(dto.schools[0]['id'], 136);
      expect(schoolShiftIdsOf(dto.schools[0]), [2, 3]);
    });

    test('coverage.schools como lista de ints continua funcionando', () {
      final dto = DriverProfileDto.fromJson(
        baseJson(
          schools: [1, 2],
          schoolShiftMap: <String, dynamic>{
            '1': [1, 2],
            '2': [2],
          },
        ),
      );

      expect(dto.schools, hasLength(2));
      expect(dto.schools[0]['id'], 1);
      expect(schoolShiftIdsOf(dto.schools[0]), [1, 2]);
      expect(dto.schools[1]['id'], 2);
      expect(schoolShiftIdsOf(dto.schools[1]), [2]);
    });

    test('schools legadas (cache) têm precedência sobre coverage.schools', () {
      final json = baseJson(
        schools: [
          <String, dynamic>{
            'schoolId': 999,
            'name': 'Do coverage',
            'shiftIds': [1],
          },
        ],
      );
      json['schools'] = [
        <String, dynamic>{
          'id': 42,
          'name': 'Do cache legado',
          'shiftIds': [4, 5],
        },
      ];

      final dto = DriverProfileDto.fromJson(json);

      expect(dto.schools, hasLength(1));
      expect(dto.schools[0]['id'], 42);
      expect(dto.schools[0]['name'], 'Do cache legado');
      expect(schoolShiftIdsOf(dto.schools[0]), [4, 5]);
    });

    test('districtShiftMap objeto string-keyed continua parseando (regressão)',
        () {
      final dto = DriverProfileDto.fromJson(
        baseJson(
          schools: [
            <String, dynamic>{'schoolId': 1, 'shiftIds': [1]},
          ],
          districtShiftMap: <String, dynamic>{
            '59': [1, 3, 4],
            '178': [2, 4],
          },
        ),
      );

      expect(dto.districtShiftMap, {
        59: [1, 3, 4],
        178: [2, 4],
      });
      expect(dto.districts, hasLength(2));
      expect((dto.districts[0]['shiftIds'] as List).cast<int>(), [1, 3, 4]);
      expect((dto.districts[1]['shiftIds'] as List).cast<int>(), [2, 4]);
    });
  });
}
