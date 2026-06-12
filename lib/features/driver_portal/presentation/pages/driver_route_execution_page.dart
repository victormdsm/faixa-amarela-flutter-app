import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/route_manifest.dart';
import '../providers/driver_portal_providers.dart';

class DriverRouteExecutionPage extends ConsumerWidget {
  const DriverRouteExecutionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeAsync = ref.watch(driverRouteControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Execucao da rota'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(driverRouteControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: routeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () =>
              ref.read(driverRouteControllerProvider.notifier).refresh(),
        ),
        data: (route) {
          if (route == null) {
            return _EmptyState(
              message: 'Nenhuma rota ativa no momento.',
              onAction: () => context.go(AppRoutes.driverHome),
              actionLabel: 'Voltar ao inicio',
            );
          }
          return _RouteBody(route: route);
        },
      ),
    );
  }
}

class _RouteBody extends ConsumerWidget {
  const _RouteBody({required this.route});

  final RouteManifest route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardedCount = route.stops
        .where((s) => s.status == StopStatus.boarded)
        .length;
    final pendingCount = route.stops
        .where((s) => s.status == StopStatus.pending)
        .length;

    return Column(
      children: [
        // Header stats
        Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border.withAlpha(180)),
          ),
          child: Row(
            children: [
              _StatChip(
                label: 'Paradas',
                value: '${route.stops.length}',
                color: AppColors.ink,
              ),
              const SizedBox(width: AppSpacing.md),
              _StatChip(
                label: 'Embarcados',
                value: '$boardedCount',
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.md),
              _StatChip(
                label: 'Pendentes',
                value: '$pendingCount',
                color: AppColors.yellowDark,
              ),
            ],
          ),
        ),

        // Bulk disembark button
        if (boardedCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showBulkDisembarkDialog(context, ref, route),
                icon: const Icon(Icons.school_outlined),
                label: const Text('Entregar todos na escola'),
              ),
            ),
          ),

        const SizedBox(height: AppSpacing.lg),

        // Stops list
        Expanded(
          child: route.stops.isEmpty
              ? const _EmptyState(message: 'Nenhuma parada nesta rota.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  itemCount: route.stops.length,
                  itemBuilder: (context, index) {
                    final stop = route.stops[index];
                    return _StopCard(stop: stop, routeId: route.id);
                  },
                ),
        ),
      ],
    );
  }

  void _showBulkDisembarkDialog(
    BuildContext context,
    WidgetRef ref,
    RouteManifest route,
  ) {
    final firstStopWithSchool = route.stops
        .where((s) => s.schoolId != null && s.schoolId! > 0)
        .firstOrNull;
    final schoolName = firstStopWithSchool?.schoolName ??
        route.stops.firstOrNull?.schoolName ??
        'escola';
    final schoolId = firstStopWithSchool?.schoolId ?? 0;

    if (schoolId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel identificar a escola desta rota.'),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Entregar todos na escola'),
        content: Text(
          'Deseja marcar todos os alunos embarcados como entregues na escola ($schoolName)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref
                  .read(driverRouteControllerProvider.notifier)
                  .bulkDisembarkAtSchool(schoolId);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

class _StopCard extends ConsumerWidget {
  const _StopCard({required this.stop, required this.routeId});

  final RouteStop stop;
  final int routeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (statusLabel, statusColor) = _stopStatusInfo(stop.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    _stopIcon(stop.status),
                    color: statusColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.childName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        stop.schoolName,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    statusLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              stop.address,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (stop.status == StopStatus.pending)
                  _ActionButton(
                    label: 'Embarcou',
                    icon: Icons.login_rounded,
                    onPressed: () => ref
                        .read(driverRouteControllerProvider.notifier)
                        .markBoarded(stop.childId),
                  ),
                if (stop.status == StopStatus.boarded)
                  _ActionButton(
                    label: 'Desembarcou',
                    icon: Icons.logout_rounded,
                    onPressed: () => ref
                        .read(driverRouteControllerProvider.notifier)
                        .markDisembarked(stop.childId),
                  ),
                if (stop.status == StopStatus.pending)
                  _ActionButton(
                    label: 'Ausente',
                    icon: Icons.person_off_outlined,
                    isSecondary: true,
                    onPressed: () => ref
                        .read(driverRouteControllerProvider.notifier)
                        .markAbsent(stop.childId),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (String, Color) _stopStatusInfo(StopStatus status) {
    return switch (status) {
      StopStatus.pending => ('Pendente', AppColors.yellowDark),
      StopStatus.boarded => ('Embarcado', AppColors.success),
      StopStatus.disembarked => ('Entregue', AppColors.info),
      StopStatus.absent => ('Ausente', AppColors.danger),
      StopStatus.removed => ('Removido', AppColors.muted),
    };
  }

  IconData _stopIcon(StopStatus status) {
    return switch (status) {
      StopStatus.pending => Icons.schedule_rounded,
      StopStatus.boarded => Icons.check_circle_outline_rounded,
      StopStatus.disembarked => Icons.done_all_rounded,
      StopStatus.absent => Icons.person_off_outlined,
      StopStatus.removed => Icons.delete_outline_rounded,
    };
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isSecondary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    if (isSecondary) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: Theme.of(context).textTheme.labelMedium,
        ),
      );
    }
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, this.onAction, this.actionLabel});

  final String message;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route_outlined, size: 48, color: AppColors.muted),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.slate),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.home_outlined),
                label: Text(actionLabel!),
              ),
            ],
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
              'Erro ao carregar rota',
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
