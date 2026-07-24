import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../tracking/presentation/state/driver_tracking_state.dart';
import '../providers/driver_portal_providers.dart';

/// Seção de alertas gerais para todos os responsáveis dos alunos na rota.
class DriverGeneralAlertSection extends ConsumerStatefulWidget {
  const DriverGeneralAlertSection({super.key, required this.tracking});

  final DriverTrackingState tracking;

  @override
  ConsumerState<DriverGeneralAlertSection> createState() =>
      _DriverGeneralAlertSectionState();
}

class _DriverGeneralAlertSectionState
    extends ConsumerState<DriverGeneralAlertSection> {
  bool _sending = false;

  static const _alertTypes = <(String, String, IconData, Color)>[
    ('breakdown', 'Van quebrou', Icons.car_crash_rounded, AppColors.danger),
    (
      'flat_tire',
      'Pneu furou',
      Icons.tire_repair_rounded,
      AppColors.warning,
    ),
    ('accident', 'Acidente', Icons.warning_amber_rounded, AppColors.danger),
    ('general', 'Atraso geral', Icons.schedule_rounded, AppColors.warning),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.campaign_rounded,
                size: 20,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Alerta geral para todos os responsáveis',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _alertTypes.map((t) {
              final (type, label, icon, color) = t;
              return _AlertTypeButton(
                icon: icon,
                label: label,
                color: color,
                enabled: !_sending,
                onTap: () => _sendAlert(type, label),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _sendAlert(String type, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enviar alerta geral?'),
        content: Text(
          'Todos os responsáveis dos alunos na rota serão notificados: "$label".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Enviar alerta'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final routeId = widget.tracking.routeId;
    if (routeId == null || routeId <= 0) return;

    setState(() => _sending = true);
    try {
      await ref.read(driverRoutesRepositoryProvider).alertAll(routeId, type);
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: 'Alerta enviado aos responsáveis.',
        type: AppFeedbackType.success,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, type: AppFeedbackType.error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _AlertTypeButton extends StatelessWidget {
  const _AlertTypeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? color.withValues(alpha: 0.10)
          : AppColors.muted.withValues(alpha: 0.08),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: enabled ? color : AppColors.slate),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: enabled ? color : AppColors.slate,
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
