import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/driver_profile.dart';
import '../../../../domain/models/route_manifest.dart';
import '../providers/driver_portal_providers.dart';
import '../state/driver_dashboard_controller.dart';

class DriverDashboardPage extends ConsumerWidget {
  const DriverDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(driverDashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Area do Motorista'),
        actions: [
          IconButton(
            tooltip: 'Configuracoes',
            onPressed: () => context.push(AppRoutes.driverSettings),
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            onPressed: () =>
                ref.read(driverDashboardControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () =>
              ref.read(driverDashboardControllerProvider.notifier).refresh(),
        ),
        data: (state) => _DashboardBody(state: state),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.state});

  final DriverDashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = state.profile;
    final activeRoute = state.activeRoute;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(driverDashboardControllerProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Profile card
          _ProfileCard(profile: profile),
          const SizedBox(height: AppSpacing.lg),

          // Quick actions
          _QuickActionsCard(),
          const SizedBox(height: AppSpacing.lg),

          // Active route or start route
          if (activeRoute != null && activeRoute.status != RouteStatus.finished)
            _ActiveRouteCard(route: activeRoute)
          else
            const _StartRouteCard(),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({this.profile});

  final DriverProfile? profile;

  @override
  Widget build(BuildContext context) {
    final name = profile?.name ?? 'Motorista';
    final vanPlate = profile?.vanPlate ?? 'Placa nao informada';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.yellowLight,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(
                    Icons.directions_bus_filled_outlined,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Van: $vanPlate',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveRouteCard extends StatelessWidget {
  const _ActiveRouteCard({required this.route});

  final RouteManifest route;

  @override
  Widget build(BuildContext context) {
    final pendingStops = route.stops
        .where((s) => s.status == StopStatus.pending)
        .length;
    final boardedStops = route.stops
        .where((s) => s.status == StopStatus.boarded)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.successSurface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rota em andamento',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${route.stops.length} paradas',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: route.status),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _MetricChip(
                  label: 'Pendentes',
                  value: '$pendingStops',
                  color: AppColors.yellowDark,
                ),
                const SizedBox(width: AppSpacing.md),
                _MetricChip(
                  label: 'Embarcados',
                  value: '$boardedStops',
                  color: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.driverRouteExecution),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Continuar rota'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acoes rapidas',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.person_search_outlined,
                    label: 'Buscar crianca',
                    onTap: () => context.push(AppRoutes.driverLookup),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.school_outlined,
                    label: 'Matriculas',
                    onTap: () => context.push(AppRoutes.driverEnrollments),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border.withAlpha(140)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.ink),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartRouteCard extends ConsumerWidget {
  const _StartRouteCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(driverDashboardControllerProvider).isLoading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Iniciar nova rota',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Nenhuma rota ativa no momento. Inicie uma nova rota quando estiver pronto.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isLoading
                    ? null
                    : () => ref
                          .read(driverDashboardControllerProvider.notifier)
                          .startRoute(),
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: const Text('Iniciar rota'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final RouteStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      RouteStatus.active => ('Ativa', AppColors.success),
      RouteStatus.finished => ('Finalizada', AppColors.muted),
      RouteStatus.planning => ('Planejamento', AppColors.info),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(AppRadius.full),
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

class _MetricChip extends StatelessWidget {
  const _MetricChip({
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
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.slate),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.danger,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Erro ao carregar dados',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
