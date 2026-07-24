import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Chip de ação compacto usado nos cards de alunos da rota ativa.
class DriverActionChip extends StatelessWidget {
  const DriverActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = enabled ? color : AppColors.slate.withValues(alpha: 0.5);
    return Material(
      color: fg.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
