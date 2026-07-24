import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import 'dashboard_models.dart';

/// Grade de acoes rapidas para dashboards.
///
/// O numero de colunas pode ser ajustado via [crossAxisCount].
class DashboardActionGrid extends StatelessWidget {
  const DashboardActionGrid({
    super.key,
    required this.actions,
    this.crossAxisCount = 3,
  });

  final List<PortalHomeAction> actions;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: crossAxisCount == 2 ? 1.15 : 0.95,
      ),
      itemBuilder: (context, index) {
        final item = actions[index];
        final color = item.color ?? AppColors.ink;
        final button = InkWell(
          key: item.key,
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: color, size: 28),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    item.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );

        if (item.tooltip case final tooltip?) {
          return Tooltip(message: tooltip, child: button);
        }
        return button;
      },
    );
  }
}
