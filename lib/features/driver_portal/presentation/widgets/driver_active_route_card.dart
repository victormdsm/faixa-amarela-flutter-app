import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_status_card.dart';
import '../../../../domain/models/route_manifest.dart';

/// Card exibido quando o motorista possui uma rota ativa em andamento.
class DriverActiveRouteCard extends StatelessWidget {
  const DriverActiveRouteCard({
    super.key,
    required this.route,
    this.onAccess,
  });

  final RouteManifest route;
  final VoidCallback? onAccess;

  @override
  Widget build(BuildContext context) {
    final totalStops = route.stops.length;
    final boardedStops = route.stops
        .where((s) => s.status == StopStatus.boarded)
        .length;
    final progress = totalStops == 0 ? 0.0 : boardedStops / totalStops;
    final schoolName = route.stops
        .where((s) => s.schoolName.isNotEmpty)
        .firstOrNull
        ?.schoolName;

    return DashboardStatusCard(
      active: true,
      title: 'Rota em andamento',
      subtitle: schoolName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso de embarque',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.ink),
              ),
              Text(
                '$boardedStops / $totalStops embarcados',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surface.withValues(alpha: 0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ink),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAccess,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Acessar Rota'),
            ),
          ),
        ],
      ),
    );
  }
}
