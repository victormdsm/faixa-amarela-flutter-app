import 'package:app_faixa_amarela/features/driver_portal/presentation/pages/driver_settings_change_detection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hasVehicleDataChanges', () {
    bool detect({
      String brand = 'Fiat Ducato',
      String color = 'Branca',
      String year = '2020',
      String plate = 'ABC1234',
    }) {
      return hasVehicleDataChanges(
        brand: brand,
        color: color,
        year: year,
        plate: plate,
        originalBrand: 'Fiat Ducato',
        originalColor: 'Branca',
        originalYear: '2020',
        originalPlate: 'ABC1234',
      );
    }

    test('returns false when nothing changed', () {
      expect(detect(), isFalse);
    });

    test('returns true when plate changed', () {
      expect(detect(plate: 'XYZ1A23'), isTrue);
    });

    test('returns true when brand changed', () {
      expect(detect(brand: 'Mercedes Sprinter'), isTrue);
    });

    test('returns true when color changed', () {
      expect(detect(color: 'Azul'), isTrue);
    });

    test('returns true when year changed', () {
      expect(detect(year: '2021'), isTrue);
    });
  });

  group('hasCoverageChanges', () {
    bool detect({
      Set<int>? selectedSchoolIds,
      Set<int>? originalSelectedSchoolIds,
      Map<int, Set<int>>? districtShiftMap,
      Map<int, Set<int>>? originalDistrictShiftMap,
      bool hasNewAvatarImage = false,
      bool hasNewVehicleImage = false,
      bool vehicleEdited = false,
    }) {
      return hasCoverageChanges(
        selectedSchoolIds: selectedSchoolIds ?? const {1, 2},
        originalSelectedSchoolIds: originalSelectedSchoolIds ?? const {1, 2},
        districtShiftMap: districtShiftMap ?? const {
          10: {1, 2},
        },
        originalDistrictShiftMap: originalDistrictShiftMap ?? const {
          10: {1, 2},
        },
        hasNewAvatarImage: hasNewAvatarImage,
        hasNewVehicleImage: hasNewVehicleImage,
        hasVehicleDataChanges: vehicleEdited,
      );
    }

    test('returns false when nothing changed', () {
      expect(detect(), isFalse);
    });

    test('returns true when schools changed', () {
      expect(detect(selectedSchoolIds: const {1, 3}), isTrue);
    });

    test('returns true when district shifts changed', () {
      expect(
        detect(
          districtShiftMap: const {
            10: {1},
          },
        ),
        isTrue,
      );
    });

    test('returns true when a district was added', () {
      expect(
        detect(
          districtShiftMap: const {
            10: {1, 2},
            20: {1},
          },
        ),
        isTrue,
      );
    });

    test('returns true for new avatar image', () {
      expect(detect(hasNewAvatarImage: true), isTrue);
    });

    test('returns true for new vehicle image', () {
      expect(detect(hasNewVehicleImage: true), isTrue);
    });

    test('returns true for vehicle data edit even without any other change',
        () {
      // Garante que editar só os dados da van entra no fluxo de solicitação
      // de aprovação (senão o _save nem chamaria o submitRequest).
      expect(detect(vehicleEdited: true), isTrue);
    });
  });

  group('hasDistrictShiftChanges (APP-02)', () {
    bool detect({
      Map<int, Set<int>>? districtShiftMap,
      Map<int, Set<int>>? originalDistrictShiftMap,
    }) {
      return hasDistrictShiftChanges(
        districtShiftMap: districtShiftMap ?? const {
          10: {1, 2},
        },
        originalDistrictShiftMap: originalDistrictShiftMap ?? const {
          10: {1, 2},
        },
      );
    }

    test('returns false when the map is untouched (ex.: só trocou a foto)', () {
      expect(detect(), isFalse);
    });

    test('returns true when a shift was toggled', () {
      expect(
        detect(
          districtShiftMap: const {
            10: {1},
          },
        ),
        isTrue,
      );
    });

    test('returns true when a district was added', () {
      expect(
        detect(
          districtShiftMap: const {
            10: {1, 2},
            20: {1},
          },
        ),
        isTrue,
      );
    });

    test('returns true when a district was removed', () {
      expect(detect(districtShiftMap: const {}), isTrue);
    });
  });
}
