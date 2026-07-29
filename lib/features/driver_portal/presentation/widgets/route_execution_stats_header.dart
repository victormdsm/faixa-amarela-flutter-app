import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Header com estatísticas da rota em execução.
class RouteExecutionStatsHeader extends StatelessWidget {
  const RouteExecutionStatsHeader({
    super.key,
    required this.totalStops,
    required this.boardedCount,
    required this.pendingCount,
  });

  final int totalStops;
  final int boardedCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          _StatCard(label: 'Total', value: '$totalStops', color: AppColors.ink),
          const SizedBox(width: AppSpacing.md),
          _StatCard(
            label: 'Embarcados',
            value: '$boardedCount',
            color: AppColors.statusBoarded,
          ),
          const SizedBox(width: AppSpacing.md),
          _StatCard(
            label: 'Pendentes',
            value: '$pendingCount',
            color: AppColors.warningInk,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowSubtle,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.slate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
