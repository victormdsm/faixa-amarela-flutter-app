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
      Set<int>? selectedDistrictIds,
      Set<int>? originalSelectedDistrictIds,
      bool hasNewAvatarImage = false,
      bool hasNewVehicleImage = false,
      bool vehicleEdited = false,
      bool publicContactEdited = false,
      bool descriptionEdited = false,
    }) {
      return hasCoverageChanges(
        selectedSchoolIds: selectedSchoolIds ?? const {1, 2},
        originalSelectedSchoolIds: originalSelectedSchoolIds ?? const {1, 2},
        selectedDistrictIds: selectedDistrictIds ?? const {10},
        originalSelectedDistrictIds: originalSelectedDistrictIds ?? const {10},
        hasNewAvatarImage: hasNewAvatarImage,
        hasNewVehicleImage: hasNewVehicleImage,
        hasVehicleDataChanges: vehicleEdited,
        hasPublicContactChanges: publicContactEdited,
        hasDescriptionChanges: descriptionEdited,
      );
    }

    test('returns false when nothing changed', () {
      expect(detect(), isFalse);
    });

    test('returns true when schools changed', () {
      expect(detect(selectedSchoolIds: const {1, 3}), isTrue);
    });

    test('returns true when a district was added', () {
      expect(detect(selectedDistrictIds: const {10, 20}), isTrue);
    });

    test('returns true when a district was removed', () {
      expect(detect(selectedDistrictIds: const {}), isTrue);
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

    test('returns true for public contact edit (vai para aprovação)', () {
      expect(detect(publicContactEdited: true), isTrue);
    });

    test('returns true for description edit (vai para aprovação)', () {
      expect(detect(descriptionEdited: true), isTrue);
    });
  });

  group('hasPublicContactChanges / hasDescriptionChanges', () {
    test('contato: false quando nada mudou, true quando nome ou fone mudou', () {
      expect(
        hasPublicContactChanges(
          name: 'Van do Carlos',
          phone: '45999990000',
          originalName: 'Van do Carlos',
          originalPhone: '45999990000',
        ),
        isFalse,
      );
      expect(
        hasPublicContactChanges(
          name: 'Van Escolar',
          phone: '45999990000',
          originalName: 'Van do Carlos',
          originalPhone: '45999990000',
        ),
        isTrue,
      );
      expect(
        hasPublicContactChanges(
          name: 'Van do Carlos',
          phone: '45988887777',
          originalName: 'Van do Carlos',
          originalPhone: '45999990000',
        ),
        isTrue,
      );
    });

    test('descrição: false quando igual, true quando editada', () {
      expect(
        hasDescriptionChanges(
          description: 'Bio',
          originalDescription: 'Bio',
        ),
        isFalse,
      );
      expect(
        hasDescriptionChanges(
          description: 'Bio nova',
          originalDescription: 'Bio',
        ),
        isTrue,
      );
    });
  });

  group('validatePublicContactField (obrigatório)', () {
    test('vazio/null/espaços → mensagem amigável', () {
      expect(validatePublicContactField(null), publicContactRequiredMessage);
      expect(validatePublicContactField(''), publicContactRequiredMessage);
      expect(validatePublicContactField('   '), publicContactRequiredMessage);
      expect(
        publicContactRequiredMessage,
        'Preencha o nome e telefone de contato público.',
      );
    });

    test('preenchido → sem erro', () {
      expect(validatePublicContactField('Van do Carlos'), isNull);
      expect(validatePublicContactField('45999990000'), isNull);
    });
  });

  group('hasDistrictChanges', () {
    bool detect({
      Set<int>? selectedDistrictIds,
      Set<int>? originalSelectedDistrictIds,
    }) {
      return hasDistrictChanges(
        selectedDistrictIds: selectedDistrictIds ?? const {10, 20},
        originalSelectedDistrictIds: originalSelectedDistrictIds ??
            const {10, 20},
      );
    }

    test('returns false when the list is untouched (ex.: só trocou a foto)', () {
      expect(detect(), isFalse);
    });

    test('returns true when a district was added', () {
      expect(detect(selectedDistrictIds: const {10, 20, 30}), isTrue);
    });

    test('returns true when a district was removed', () {
      expect(detect(selectedDistrictIds: const {10}), isTrue);
    });
  });
}
