import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import 'dashboard/dashboard_action_grid.dart';
import 'dashboard/dashboard_header.dart';
import 'dashboard/dashboard_metric_grid.dart';
import 'dashboard/dashboard_models.dart';
import 'dashboard/dashboard_section_title.dart';
import 'dashboard/dashboard_status_card.dart';
import 'faixa_app_bar.dart';

export 'dashboard/dashboard_models.dart';

/// Wrapper legado da home do portal.
///
/// Mantido para compatibilidade com consumidores antigos. Novas dashboards
/// devem montar o layout diretamente com [DashboardHeader], [DashboardMetricGrid],
/// [DashboardActionGrid] e [DashboardStatusCard].
@Deprecated(
  'Use os widgets de dashboard especificos por persona em vez deste wrapper.',
)
class FaixaPortalHome extends StatelessWidget {
  const FaixaPortalHome({
    super.key,
    required this.userName,
    required this.roleLabel,
    required this.statusLabel,
    required this.statusActive,
    required this.metrics,
    required this.actions,
    this.onRefresh,
    this.onProfileTap,
    this.bottomContent,
    this.greeting,
    this.greetingSubtitle,
    this.statusCardSubtitle,
    this.statusCard,
  });

  final String userName;
  final String roleLabel;
  final String statusLabel;
  final bool statusActive;
  final List<PortalHomeMetric> metrics;
  final List<PortalHomeAction> actions;
  final VoidCallback? onRefresh;
  final VoidCallback? onProfileTap;
  final Widget? bottomContent;

  /// Saudacao customizada. Se nao informada, usa "Ola, {primeiroNome}!".
  final String? greeting;

  /// Subtitulo customizado abaixo da saudacao.
  final String? greetingSubtitle;

  /// Subtitulo customizado do card de status.
  final String? statusCardSubtitle;

  /// Widget customizado que substitui o card de status padrao.
  final Widget? statusCard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      appBar: FaixaAppBar.portal(
        actions: [
          if (onProfileTap != null)
            IconButton(
              tooltip: 'Perfil',
              onPressed: onProfileTap,
              icon: const Icon(Icons.account_circle_outlined),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => onRefresh?.call(),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            DashboardHeader(
              userName: userName,
              greeting: greeting,
              subtitle: greetingSubtitle,
            ),
            const SizedBox(height: AppSpacing.lg),
            statusCard ??
                DashboardStatusCard(
                  active: statusActive,
                  title: statusLabel,
                  subtitle: statusCardSubtitle ??
                      (statusActive
                          ? 'Acompanhe a localizacao em tempo real.'
                          : 'Nenhuma rota ativa no momento.'),
                ),
            const SizedBox(height: AppSpacing.xl),
            const DashboardSectionTitle('Resumo'),
            const SizedBox(height: AppSpacing.md),
            DashboardMetricGrid(metrics: metrics),
            const SizedBox(height: AppSpacing.xl),
            const DashboardSectionTitle('Acoes Rapidas'),
            const SizedBox(height: AppSpacing.md),
            DashboardActionGrid(actions: actions),
            if (bottomContent != null) ...[
              const SizedBox(height: AppSpacing.xl),
              bottomContent!,
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
