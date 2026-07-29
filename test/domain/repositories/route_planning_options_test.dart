import 'package:app_faixa_amarela/domain/repositories/routes_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlanningChild.fromJson', () {
    test('selectedByDefault ausente na resposta cai em true (backend antigo)',
        () {
      final child = PlanningChild.fromJson(const {
        'childId': 10,
        'childName': 'Ana Silva',
        'schoolId': 3,
        'schoolName': 'Escola Alfa',
      });

      expect(child.selectedByDefault, isTrue);
      expect(child.schoolId, 3);
      expect(child.schoolName, 'Escola Alfa');
    });

    test('selectedByDefault false explícito é respeitado (integral manhã_volta)',
        () {
      final child = PlanningChild.fromJson(const {
        'childId': 11,
        'childName': 'Bruno Souza',
        'schoolId': 3,
        'schoolName': 'Escola Alfa',
        'selectedByDefault': false,
      });

      expect(child.selectedByDefault, isFalse);
    });

    test('selectedByDefault true explícito é respeitado', () {
      final child = PlanningChild.fromJson(const {
        'childId': 12,
        'childName': 'Carla Lima',
        'selectedByDefault': true,
      });

      expect(child.selectedByDefault, isTrue);
      expect(child.schoolId, isNull);
    });
  });

  group('RoutePlanningOptions.fromJson', () {
    test('mantém a ordem recebida e propaga selectedByDefault por criança',
        () {
      final options = RoutePlanningOptions.fromJson(const {
        'children': [
          {
            'childId': 10,
            'childName': 'Ana Silva',
            'schoolId': 1,
            'schoolName': 'Escola Alfa',
          },
          {
            'childId': 11,
            'childName': 'Bruno Souza',
            'schoolId': 1,
            'schoolName': 'Escola Alfa',
            'selectedByDefault': false,
          },
          {
            'childId': 12,
            'childName': 'Carla Lima',
            'schoolId': 2,
            'schoolName': 'Escola Beta',
          },
        ],
      });

      expect(options.children.map((c) => c.id), [10, 11, 12]);
      expect(options.children[0].selectedByDefault, isTrue);
      expect(options.children[1].selectedByDefault, isFalse);
      expect(options.children[2].selectedByDefault, isTrue);
      expect(options.children[2].schoolId, 2);
    });
  });
}
