import 'package:app_faixa_amarela/features/parent_portal/presentation/widgets/parent_children_strip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveChildBoardingStatus (APP-04 / APP-08)', () {
    Map<String, dynamic> boarding({
      required int childId,
      required String childName,
      required String status,
    }) {
      // Mesmo formato de GET /parent/boardings (ver parent_boardings_page).
      return <String, dynamic>{
        'id': 99,
        'status': status,
        'boarding': <String, dynamic>{
          'id': 5,
          'route': <String, dynamic>{'id': 3, 'name': 'Rota de Joao'},
          'hourBoarding': '2026-07-30T11:00:00.000Z',
        },
        'client': <String, dynamic>{
          'id': childId,
          'child': <String, dynamic>{'id': childId, 'name': childName},
        },
      };
    }

    test('casa filho↔boarding por client.child.id e marca Embarcou', () {
      final status = resolveChildBoardingStatus(
        childId: 7,
        childName: 'Ana',
        boardings: [boarding(childId: 7, childName: 'Ana', status: 'boarded')],
      );

      expect(status, ChildBoardingStatus.boarded);
    });

    test('boarding de OUTRO filho não contamina o badge', () {
      final status = resolveChildBoardingStatus(
        childId: 7,
        childName: 'Ana',
        boardings: [boarding(childId: 8, childName: 'Bia', status: 'boarded')],
      );

      expect(status, ChildBoardingStatus.waiting);
    });

    test('absent vira "Não embarcou" (APP-08)', () {
      final status = resolveChildBoardingStatus(
        childId: 7,
        childName: 'Ana',
        boardings: [boarding(childId: 7, childName: 'Ana', status: 'absent')],
      );

      expect(status, ChildBoardingStatus.notBoarded);
    });

    test('fallback por nome quando o id não casa', () {
      final status = resolveChildBoardingStatus(
        childId: 7,
        childName: 'Ana',
        boardings: [boarding(childId: 0, childName: 'ana', status: 'boarded')],
      );

      expect(status, ChildBoardingStatus.boarded);
    });

    test('sem boardings fica Aguardando', () {
      final status = resolveChildBoardingStatus(
        childId: 7,
        childName: 'Ana',
        boardings: const [],
      );

      expect(status, ChildBoardingStatus.waiting);
    });
  });
}
