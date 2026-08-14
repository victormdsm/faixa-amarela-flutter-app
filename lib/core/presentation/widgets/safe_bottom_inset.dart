import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// Respiro inferior seguro para conteúdo ancorado/rolável.
///
/// Em aparelhos com barra de navegação por gestos ou com skins que desenham
/// a própria barra (MIUI), o último botão da tela ficava embaixo dos botões
/// de navegação do sistema — em alguns casos impossível de tocar. São dois
/// problemas distintos:
///
/// * a view desenha por baixo da barra do sistema — coberto por
///   `MediaQuery.padding.bottom`;
/// * a skin reporta `padding.bottom == 0` mas ainda sobrepõe uma faixa —
///   coberto pelo piso [minimum].
///
/// Use [safeBottomInset] no padding de listas/scroll views e
/// [SafeBottomArea] em barras de ação ancoradas no rodapé.
double safeBottomInset(
  BuildContext context, {
  double minimum = AppSpacing.xl,
}) {
  final systemInset = MediaQuery.paddingOf(context).bottom;
  return systemInset > minimum ? systemInset : minimum;
}

/// [SafeArea] inferior com piso mínimo — para barras de ação no rodapé.
class SafeBottomArea extends StatelessWidget {
  const SafeBottomArea({
    super.key,
    required this.child,
    this.minimum = AppSpacing.md,
  });

  final Widget child;
  final double minimum;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(bottom: minimum),
      child: child,
    );
  }
}
