import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../domain/models/child.dart';

/// Overlay inferior exibido no acompanhamento de rota com badge ao vivo e
/// lista de dependentes do responsável na rota selecionada.
class LiveTrackingOverlay extends StatelessWidget {
  const LiveTrackingOverlay({
    super.key,
    required this.dependents,
    this.driverPos,
    this.lastPositionAt,
    this.isLive = true,
  });

  final List<Child> dependents;
  final LatLng? driverPos;

  /// Timestamp da última posição recebida, quando o modelo o expõe.
  final DateTime? lastPositionAt;

  /// Socket conectado ("AO VIVO") ou não ("RECONECTANDO" — momento em que o
  /// polling HTTP de fallback assume a atualização do marcador).
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = isLive ? AppColors.success : AppColors.warning;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSubtle,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppPulsingDot(color: badgeColor),
                    const SizedBox(width: AppSpacing.sm - 2),
                    Text(
                      isLive ? 'AO VIVO' : 'RECONECTANDO',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isLive ? AppColors.success : AppColors.warningInk,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (driverPos == null)
                Text(
                  'Aguardando GPS do motorista…',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.slate,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else if (lastPositionAt != null)
                Text(
                  'Atualizado ${timeAgo(lastPositionAt)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.slate,
                  ),
                ),
            ],
          ),
          if (dependents.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Meus dependentes nesta rota',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.slate,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm - 2,
              runSpacing: AppSpacing.sm - 2,
              children: dependents.map((dep) {
                final name = dep.name;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: AppColors.yellow.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.child_care_rounded,
                        size: 13,
                        color: AppColors.yellowDark,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        name.isEmpty ? 'Dependente' : name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.yellowDark,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
