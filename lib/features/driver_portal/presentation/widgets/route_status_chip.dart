import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/route_manifest.dart';

/// Chip com o status da rota (Ativa, Finalizada, Planejamento).
class RouteStatusChip extends StatelessWidget {
  const RouteStatusChip({super.key, required this.status});

  final RouteStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, surfaceColor) = switch (status) {
      RouteStatus.active => (
        'Ativa',
        AppColors.statusBoarded,
        AppColors.successSurface,
      ),
      RouteStatus.finished => (
        'Finalizada',
        AppColors.muted,
        AppColors.surfaceSoft,
      ),
      RouteStatus.planning => (
        'Planejamento',
        AppColors.info,
        AppColors.infoSurface,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
