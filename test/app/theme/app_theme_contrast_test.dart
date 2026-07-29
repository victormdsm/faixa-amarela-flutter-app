import 'package:app_faixa_amarela/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Razão de contraste WCAG entre duas cores ((L1 + 0.05) / (L2 + 0.05)).
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// Regressão do bug reportado: "a cor das letras é clara e o fundo branco
/// não tem como enxergar" nas telas de rota/planning/execução do motorista.
/// Garante que texto e botões dessas telas ficam acima do AA (4.5:1).
void main() {
  const aaNormalText = 4.5;

  group('contraste do tema (WCAG AA)', () {
    test('FilledButton: texto sobre o amarelo da marca', () {
      final style = AppTheme.light().filledButtonTheme.style;
      final fg = style?.foregroundColor?.resolve(const {});
      final bg = style?.backgroundColor?.resolve(const {});
      expect(bg, AppColors.yellow);
      expect(fg, isNotNull);
      expect(_contrast(fg!, bg!), greaterThanOrEqualTo(aaNormalText));
    });

    test('OutlinedButton: texto sobre fundo branco', () {
      final style = AppTheme.light().outlinedButtonTheme.style;
      final fg = style?.foregroundColor?.resolve(const {});
      expect(fg, isNotNull);
      expect(_contrast(fg!, AppColors.surface), greaterThanOrEqualTo(aaNormalText));
    });

    test('FAB: ícone/texto sobre o amarelo', () {
      final theme = AppTheme.light().floatingActionButtonTheme;
      expect(theme.backgroundColor, AppColors.yellow);
      expect(
        _contrast(theme.foregroundColor!, AppColors.yellow),
        greaterThanOrEqualTo(aaNormalText),
      );
    });

    test('cores de status das telas de rota sobre suas superfícies', () {
      final pairs = <String, (Color, Color)>{
        'Pendente (warningInk/warningSurface)': (
          AppColors.warningInk,
          AppColors.warningSurface,
        ),
        'Embarcado (statusBoarded/successSurface)': (
          AppColors.statusBoarded,
          AppColors.successSurface,
        ),
        'Ausente (dangerInk/branco)': (AppColors.dangerInk, AppColors.surface),
        'Badge contador (ink/yellowLight)': (AppColors.ink, AppColors.yellowLight),
        'Entregue (info/infoSurface)': (AppColors.info, AppColors.infoSurface),
      };
      for (final entry in pairs.entries) {
        final (fg, bg) = entry.value;
        expect(
          _contrast(fg, bg),
          greaterThanOrEqualTo(aaNormalText),
          reason: '${entry.key} abaixo do AA',
        );
      }
    });
  });
}
