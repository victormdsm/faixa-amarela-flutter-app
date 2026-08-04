import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// CTA primário "Encontrar transporte escolar": botão grande, full-width,
/// com a cor da marca, ícone de ônibus e sombra — o ponto de entrada mais
/// visível para a busca pública de transporte (login e home do responsável).
class FindTransportButton extends StatelessWidget {
  const FindTransportButton({super.key, required this.onPressed, this.enabled = true});

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.directions_bus_filled_rounded, size: 24),
      label: const Text('Encontrar transporte escolar'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        textStyle: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        elevation: 4,
        shadowColor: AppColors.yellow.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }
}
