import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Card de status padrao usado em dashboards.
class DashboardStatusCard extends StatelessWidget {
  const DashboardStatusCard({
    super.key,
    required this.active,
    required this.title,
    this.subtitle,
    this.activeIcon = Icons.directions_bus_filled_rounded,
    this.inactiveIcon = Icons.info_outline_rounded,
    this.child,
  });

  final bool active;
  final String title;
  final String? subtitle;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              active ? activeIcon : inactiveIcon,
              color: active ? AppColors.ink : AppColors.muted,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: active ? AppColors.ink : AppColors.slate,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (child != null) ...[
          const SizedBox(height: AppSpacing.lg),
          child!,
        ],
      ],
    );

    if (active) {
      // Sobre o amarelo cheio do heroi L1, botoes passam a ser ink com
      // texto claro (nunca branco sobre amarelo).
      content = Theme(
        data: theme.copyWith(
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: AppColors.surface,
              minimumSize: const Size.fromHeight(48),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
        child: content,
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: active ? AppColors.yellow : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: active ? null : Border.all(color: AppColors.border),
      ),
      child: content,
    );
  }
}
