import 'package:app_faixa_amarela/domain/models/driver_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DriverProfile districtShiftMap', () {
    Map<String, dynamic> baseJson({dynamic districtShiftMap}) {
      return <String, dynamic>{
        'id': 1,
        'userId': 10,
        'name': 'Tio Joao',
        'cpf': '12345678900',
        'licenseNumber': '123456789',
        'vanId': 1,
        'vanPlate': 'ABC1234',
        'vanModel': 'Fiat Ducato',
        'vanYear': '2020',
        'coverageArea': 'Norte',
        'districts': [
          <String, dynamic>{'id': 10, 'shiftIds': [1, 2]},
          <String, dynamic>{'id': 20, 'shiftIds': [2]},
        ],
        if (districtShiftMap != null) 'districtShiftMap': districtShiftMap,
      };
    }

    test('usa mapa explícito quando presente (objeto com chaves string)', () {
      final profile = DriverProfile.fromJson(
        baseJson(
          districtShiftMap: <String, dynamic>{
            '10': [1, 2],
            '20': [3],
          },
        ),
      );

      expect(profile.districtShiftMap, {
        10: [1, 2],
        20: [3],
      });
    });

    test('tolera mapa serializado como lista de {districtId, shiftIds}', () {
      final profile = DriverProfile.fromJson(
        baseJson(
          districtShiftMap: [
            <String, dynamic>{'districtId': 10, 'shiftIds': [1, 2]},
            <String, dynamic>{'districtId': 20, 'shiftIds': [3]},
          ],
        ),
      );

      expect(profile.districtShiftMap, {
        10: [1, 2],
        20: [3],
      });
    });

    test('fallback aos shiftIds de cada bairro quando mapa está ausente', () {
      final profile = DriverProfile.fromJson(baseJson());

      expect(profile.districtShiftMap, {
        10: [1, 2],
        20: [2],
      });
    });

    test('toJson preserva districtShiftMap', () {
      final profile = DriverProfile.fromJson(
        baseJson(
          districtShiftMap: <String, dynamic>{'10': [1]},
        ),
      );

      expect(profile.toJson()['districtShiftMap'], {
        '10': [1],
      });
    });
  });
}
