import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import 'dashboard_models.dart';

/// Grade 2x2 de metricas para dashboards.
class DashboardMetricGrid extends StatelessWidget {
  const DashboardMetricGrid({super.key, required this.metrics});

  final List<PortalHomeMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) {
        final item = metrics[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: AppColors.ink, size: 18),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.ink,
              ),
            ),
            Text(
              item.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.slate,
              ),
            ),
          ],
        );
      },
    );
  }
}
