import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../domain/models/child.dart';

/// Overlay inferior exibido no acompanhamento de rota com badge ao vivo e
/// lista de dependentes do responsável na rota selecionada.
///
/// Estados da conexão em tempo real (sem jargão técnico e sem alarme):
/// - [isLive]: pill discreta "Ao vivo" (verde).
/// - fora do ar de forma transitória: pill neutra "Atualizando…" — quedas
///   curtas se resolvem sozinhas (reconexão automática + polling HTTP de
///   15s de fallback), então não merecem cara de erro.
/// - [connectionIssue] (30s+ sem conectar): mensagem clara de que os dados
///   seguem atualizando a cada 15s, com a ação "Tentar de novo" ([onRetry]).
class LiveTrackingOverlay extends StatelessWidget {
  const LiveTrackingOverlay({
    super.key,
    required this.dependents,
    this.driverPos,
    this.lastPositionAt,
    this.isLive = true,
    this.connectionIssue = false,
    this.onRetry,
  });

  final List<Child> dependents;
  final LatLng? driverPos;

  /// Timestamp da última posição recebida, quando o modelo o expõe.
  final DateTime? lastPositionAt;

  /// Socket conectado: posições chegam em tempo real.
  final bool isLive;

  /// Falha persistente de conexão em tempo real (30s+ sem conectar). Só aí
  /// exibimos mensagem de problema + ação de tentar de novo.
  final bool connectionIssue;

  /// Ação do botão "Tentar de novo" exibido no estado [connectionIssue].
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showIssue = connectionIssue && !isLive;
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
              if (showIssue) ...[
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 16,
                  color: AppColors.warningInk,
                ),
                const SizedBox(width: AppSpacing.sm - 2),
                Expanded(
                  child: Text(
                    'Sem conexão em tempo real — os dados atualizam a cada 15s.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.warningInk,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.warningInk,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('Tentar de novo'),
                ),
              ] else ...[
                _ConnectionPill(isLive: isLive),
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

/// Pill de status da conexão: verde discreta "Ao vivo" quando o socket está
/// conectado; neutra "Atualizando…" enquanto a reconexão automática e o
/// polling HTTP cobrem quedas transitórias (sem palavra de erro).
class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({required this.isLive});

  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isLive ? AppColors.success : AppColors.slate;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPulsingDot(color: color),
          const SizedBox(width: AppSpacing.sm - 2),
          Text(
            isLive ? 'Ao vivo' : 'Atualizando…',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
