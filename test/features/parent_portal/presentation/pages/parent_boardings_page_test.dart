import 'package:app_faixa_amarela/app/theme/app_theme.dart';
import 'package:app_faixa_amarela/features/parent_portal/presentation/pages/parent_boardings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('boardingStatusVisual (APP-08)', () {
    test('absent vira "Não embarcou" em vermelho com ícone de cancelado', () {
      final visual = boardingStatusVisual('absent');

      expect(visual.label, 'Não embarcou');
      expect(visual.color, AppColors.danger);
      expect(visual.icon, Icons.cancel_rounded);
    });

    test('boarded segue "Embarcado" em verde', () {
      final visual = boardingStatusVisual('boarded');

      expect(visual.label, 'Embarcado');
      expect(visual.color, AppColors.success);
    });

    test('disembarked segue "Desembarcado"', () {
      final visual = boardingStatusVisual('disembarked');

      expect(visual.label, 'Desembarcado');
      expect(visual.icon, Icons.logout_rounded);
    });

    test('status desconhecido mantém o texto original', () {
      final visual = boardingStatusVisual('pending');

      expect(visual.label, 'pending');
      expect(visual.color, AppColors.ink);
    });
  });
}
