import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../domain/models/route_manifest.dart';
import '../providers/driver_portal_providers.dart';
import 'route_execution_action_button.dart';

/// Card de parada exibido na tela de execução de rota.
class RouteExecutionStopCard extends ConsumerStatefulWidget {
  const RouteExecutionStopCard({
    super.key,
    required this.stop,
    this.showRemoveButton = false,
  });

  final RouteStop stop;
  final bool showRemoveButton;

  @override
  ConsumerState<RouteExecutionStopCard> createState() =>
      _RouteExecutionStopCardState();
}

class _RouteExecutionStopCardState
    extends ConsumerState<RouteExecutionStopCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final stop = widget.stop;
    final (statusLabel, statusColor, statusSurface) = _stopStatusInfo(
      stop.status,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StudentAvatar(name: stop.childName),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.childName.isNotEmpty ? stop.childName : 'Aluno',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _InfoRow(
                        icon: Icons.school_rounded,
                        text: stop.schoolName.isNotEmpty
                            ? stop.schoolName
                            : 'Escola não informada',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _InfoRow(
                        icon: Icons.location_on_rounded,
                        text: stop.address.isNotEmpty
                            ? stop.address
                            : 'Endereço não informado',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (stop.status == StopStatus.pending)
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  RouteExecutionActionButton(
                    label: 'Embarcar',
                    icon: Icons.login_rounded,
                    loading: _isProcessing,
                    onPressed: () => _run(
                      () => ref
                          .read(driverRouteControllerProvider.notifier)
                          .markBoarded(stop.childId),
                    ),
                  ),
                  RouteExecutionActionButton(
                    label: 'Ausente',
                    icon: Icons.person_off_rounded,
                    isSecondary: true,
                    loading: _isProcessing,
                    onPressed: () => _run(
                      () => ref
                          .read(driverRouteControllerProvider.notifier)
                          .markAbsent(stop.childId),
                    ),
                  ),
                  if (widget.showRemoveButton &&
                      stop.status != StopStatus.removed)
                    RouteExecutionActionButton(
                      label: 'Remover',
                      icon: Icons.delete_outline_rounded,
                      isSecondary: true,
                      loading: _isProcessing,
                      onPressed: () => _confirmRemove(context),
                    ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BoardedStatus(
                    label: statusLabel,
                    color: statusColor,
                    surfaceColor: statusSurface,
                  ),
                  if (stop.status == StopStatus.boarded) ...[
                    const SizedBox(height: AppSpacing.sm),
                    RouteExecutionActionButton(
                      label: 'Desembarcou',
                      icon: Icons.logout_rounded,
                      loading: _isProcessing,
                      onPressed: () => _run(
                        () => ref
                            .read(driverRouteControllerProvider.notifier)
                            .markDisembarked(stop.childId),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await action();
    } on ApiException catch (e) {
      // O controller já fez rollback do estado otimista; aqui só avisamos.
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, type: AppFeedbackType.error);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final stop = widget.stop;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        title: const Text('Remover aluno'),
        content: Text(
          'Remover ${stop.childName} desta rota? '
          'A remoção é irreversível: o aluno não poderá ser readicionado '
          'nesta rota hoje.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.surface,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _run(
      () => ref
          .read(driverRouteControllerProvider.notifier)
          .removeStudent(stop.childId),
    );
  }

  (String, Color, Color) _stopStatusInfo(StopStatus status) {
    return switch (status) {
      StopStatus.pending => (
        'Pendente',
        AppColors.warningInk,
        AppColors.warningSurface,
      ),
      StopStatus.boarded => (
        'Embarcado',
        AppColors.statusBoarded,
        AppColors.successSurface,
      ),
      StopStatus.disembarked => (
        'Entregue',
        AppColors.info,
        AppColors.infoSurface,
      ),
      StopStatus.absent => (
        'Ausente',
        AppColors.dangerInk,
        AppColors.dangerInk.withValues(alpha: 0.08),
      ),
      StopStatus.removed => (
        'Removido',
        AppColors.muted,
        AppColors.surfaceSoft,
      ),
    };
  }
}

class _StudentAvatar extends StatelessWidget {
  const _StudentAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.yellowLight,
      child: Text(
        name.trim().isNotEmpty
            ? name.trim().characters.first.toUpperCase()
            : '?',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 14, color: AppColors.slate),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
          ),
        ),
      ],
    );
  }
}

class _BoardedStatus extends StatelessWidget {
  const _BoardedStatus({
    required this.label,
    required this.color,
    required this.surfaceColor,
  });

  final String label;
  final Color color;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, color: color, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
