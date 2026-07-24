import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_theme.dart';

/// Botão de ação compacto para os cards de parada da execução de rota.
///
/// Garante touch target mínimo de 48x48 conforme diretrizes de acessibilidade.
class RouteExecutionActionButton extends StatelessWidget {
  const RouteExecutionActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isSecondary = false,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final iconWidget = loading
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon, size: 18);

    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
      textStyle: WidgetStatePropertyAll(
        Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );

    // Feedback tátil nas ações de embarque/desembarque/ausente.
    final effectiveOnPressed = (loading || onPressed == null)
        ? null
        : () {
            HapticFeedback.lightImpact();
            onPressed!();
          };

    if (isSecondary) {
      return OutlinedButton.icon(
        onPressed: effectiveOnPressed,
        icon: iconWidget,
        label: Text(label),
        style: style,
      );
    }
    return FilledButton.icon(
      onPressed: effectiveOnPressed,
      icon: iconWidget,
      label: Text(label),
      style: style,
    );
  }
}
