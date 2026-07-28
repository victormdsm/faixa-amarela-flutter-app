import 'package:app_faixa_amarela/domain/models/child.dart';
import 'package:app_faixa_amarela/features/parent_portal/presentation/state/add_child_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddChildController.addressChanged', () {
    const original = ChildAddress(
      street: 'Rua A',
      number: '100',
      complement: 'Apto 12',
      zipCode: '80000000',
      district: 'Centro',
      city: 'Curitiba',
      state: 'PR',
      latitude: -25.43,
      longitude: -49.27,
    );

    test('null original counts as changed (create-or-update flow)', () {
      expect(AddChildController.addressChanged(null, original), isTrue);
    });

    test('identical address is unchanged', () {
      final copy = ChildAddress(
        street: original.street,
        number: original.number,
        complement: original.complement,
        zipCode: original.zipCode,
        district: original.district,
        city: original.city,
        state: original.state,
        latitude: original.latitude,
        longitude: original.longitude,
      );
      expect(AddChildController.addressChanged(original, copy), isFalse);
    });

    test('field edits count as changed', () {
      ChildAddress withChanges({
        String? street,
        String? number,
        String? complement,
        String? zipCode,
        String? district,
        String? city,
        String? state,
      }) {
        return ChildAddress(
          street: street ?? original.street,
          number: number ?? original.number,
          complement: complement ?? original.complement,
          zipCode: zipCode ?? original.zipCode,
          district: district ?? original.district,
          city: city ?? original.city,
          state: state ?? original.state,
          latitude: original.latitude,
          longitude: original.longitude,
        );
      }

      expect(
        AddChildController.addressChanged(
          original,
          withChanges(street: 'Rua B'),
        ),
        isTrue,
      );
      expect(
        AddChildController.addressChanged(original, withChanges(number: '200')),
        isTrue,
      );
      expect(
        AddChildController.addressChanged(original, withChanges(city: 'Londrina')),
        isTrue,
      );
      expect(
        AddChildController.addressChanged(original, withChanges(state: 'SP')),
        isTrue,
      );
      expect(
        AddChildController.addressChanged(
          original,
          withChanges(district: 'Batel'),
        ),
        isTrue,
      );
      expect(
        AddChildController.addressChanged(
          original,
          withChanges(zipCode: '80000001'),
        ),
        isTrue,
      );
    });

    test('whitespace-only differences are ignored', () {
      const padded = ChildAddress(
        street: '  Rua A  ',
        number: ' 100 ',
        complement: ' Apto 12 ',
        zipCode: ' 80000000 ',
        district: ' Centro ',
        city: ' Curitiba ',
        state: ' PR ',
        latitude: -25.43,
        longitude: -49.27,
      );
      expect(AddChildController.addressChanged(original, padded), isFalse);
    });

    test('null vs filled optional fields count as changed', () {
      const withoutDistrict = ChildAddress(
        street: 'Rua A',
        number: '100',
        latitude: -25.43,
        longitude: -49.27,
      );
      expect(
        AddChildController.addressChanged(original, withoutDistrict),
        isTrue,
      );
    });

    test('coordinate changes use an epsilon', () {
      const noise = ChildAddress(
        street: 'Rua A',
        number: '100',
        complement: 'Apto 12',
        zipCode: '80000000',
        district: 'Centro',
        city: 'Curitiba',
        state: 'PR',
        latitude: -25.43 + 1e-7,
        longitude: -49.27 - 1e-7,
      );
      expect(AddChildController.addressChanged(original, noise), isFalse);

      const moved = ChildAddress(
        street: 'Rua A',
        number: '100',
        complement: 'Apto 12',
        zipCode: '80000000',
        district: 'Centro',
        city: 'Curitiba',
        state: 'PR',
        latitude: -25.44,
        longitude: -49.27,
      );
      expect(AddChildController.addressChanged(original, moved), isTrue);
    });

    test('adding or removing coordinates counts as changed', () {
      const withoutCoords = ChildAddress(
        street: 'Rua A',
        number: '100',
        complement: 'Apto 12',
        zipCode: '80000000',
        district: 'Centro',
        city: 'Curitiba',
        state: 'PR',
      );
      expect(
        AddChildController.addressChanged(original, withoutCoords),
        isTrue,
      );
      expect(
        AddChildController.addressChanged(withoutCoords, original),
        isTrue,
      );
      expect(
        AddChildController.addressChanged(withoutCoords, withoutCoords),
        isFalse,
      );
    });
  });
}
