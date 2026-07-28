import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/app_error_reporter.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_action_grid.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_header.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_metric_grid.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_models.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_section_title.dart';
import '../../../../core/presentation/widgets/e2e_keys.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../../ads/domain/ad.dart';
import '../../../ads/presentation/providers/ads_providers.dart';
import '../../../ads/presentation/widgets/ad_banner_widget.dart';
import '../../../ads/presentation/widgets/ad_card_widget.dart';
import '../../../../domain/models/child.dart';
import '../providers/parent_portal_providers.dart';
import '../widgets/parent_children_strip.dart';
import '../widgets/parent_route_status_card.dart';

class ParentDashboardPage extends ConsumerWidget {
  const ParentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionControllerProvider).session;
    final childrenAsync = ref.watch(parentChildrenProvider);
    final routesAsync = ref.watch(parentRoutesProvider);
    final boardingsAsync = ref.watch(parentBoardingsProvider);

    void refresh() {
      ref.invalidate(parentChildrenProvider);
      ref.invalidate(parentRoutesProvider);
      ref.invalidate(parentBoardingsProvider);
      ref.invalidate(adsProvider);
    }

    final childCount = _Counter.fromPage(childrenAsync, (p) => p.items.length);
    final routeCount = _Counter.fromPage(routesAsync, (p) => p.items.length);
    final boardingCount = _Counter.fromPage(
      boardingsAsync,
      (p) => p.items.length,
    );
    final activeRouteCount = _Counter.fromPage(
      routesAsync,
      (p) => p.items.where(_isActiveRoute).length,
    );

    final activeRoute = routesAsync.when(
      data: (page) => page.items.where(_isActiveRoute).firstOrNull,
      loading: () => null,
      error: (_, _) => null,
    );
    final children = childrenAsync.when(
      data: (page) => page.items,
      loading: () => const <Child>[],
      error: (_, _) => const <Child>[],
    );
    final boardings = boardingsAsync.when(
      data: (page) => page.items,
      loading: () => const <Map<String, dynamic>>[],
      error: (_, _) => const <Map<String, dynamic>>[],
    );

    // Falha total (os três providers em erro): estado de erro de tela inteira
    // com retry. Falhas parciais seguem degradadas (contadores "--").
    final allFailed =
        childrenAsync.hasError &&
        routesAsync.hasError &&
        boardingsAsync.hasError;

    if (allFailed) {
      return Scaffold(
        key: E2EKeys.parentHome,
        backgroundColor: AppColors.surfaceSoft,
        appBar: FaixaAppBar.portal(),
        body: FaixaErrorState(
          message: AppErrorReporter.messageFor(
            childrenAsync.error ??
                routesAsync.error ??
                boardingsAsync.error ??
                Exception('Falha ao carregar o painel.'),
          ),
          onRetry: refresh,
        ),
      );
    }

    // Subtítulo do cabeçalho com informação real (quantidade de dependentes).
    final String? headerSubtitle = childrenAsync.when(
      data: (page) => page.items.isEmpty
          ? 'Nenhum dependente cadastrado ainda.'
          : 'Acompanhando ${page.items.length} '
                '${page.items.length == 1 ? 'dependente' : 'dependentes'}.',
      loading: () => null,
      error: (_, _) => null,
    );

    return Scaffold(
      key: E2EKeys.parentHome,
      backgroundColor: AppColors.surfaceSoft,
      appBar: FaixaAppBar.portal(
        actions: [
          IconButton(
            tooltip: 'Perfil',
            onPressed: () => context.push(AppRoutes.parentProfile),
            icon: const Icon(Icons.account_circle_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => refresh(),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            DashboardHeader(
              userName: session?.user.name ?? 'Responsável',
              subtitle: headerSubtitle,
            ),
            const SizedBox(height: AppSpacing.lg),
            ParentRouteStatusCard(
              activeRoute: activeRoute,
              onViewMap: activeRoute != null
                  ? () => context.push(AppRoutes.parentRoutes)
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            const DashboardSectionTitle('Meus dependentes'),
            const SizedBox(height: AppSpacing.md),
            ParentChildrenStrip(
              children: children,
              boardings: boardings,
              onTap: (child) => _openChildDetail(context, child),
            ),
            const SizedBox(height: AppSpacing.xl),
            const DashboardSectionTitle('Resumo'),
            const SizedBox(height: AppSpacing.md),
            DashboardMetricGrid(
              metrics: [
                PortalHomeMetric(
                  label: 'Alunos',
                  value: childCount.label,
                  icon: Icons.child_care_rounded,
                ),
                PortalHomeMetric(
                  label: 'Rotas',
                  value: routeCount.label,
                  icon: Icons.route_rounded,
                ),
                PortalHomeMetric(
                  label: 'Embarques',
                  value: boardingCount.label,
                  icon: Icons.fact_check_rounded,
                ),
                PortalHomeMetric(
                  label: 'Rota Ativa',
                  value: activeRouteCount.label,
                  icon: Icons.near_me_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const DashboardSectionTitle('Ações rápidas'),
            const SizedBox(height: AppSpacing.md),
            DashboardActionGrid(
              actions: [
                PortalHomeAction(
                  label: 'Ver Rotas',
                  icon: Icons.alt_route_rounded,
                  onTap: () => _goBranch(context, 2),
                ),
                PortalHomeAction(
                  key: E2EKeys.parentChildrenAction,
                  label: 'Alunos',
                  icon: Icons.child_care_rounded,
                  onTap: () => _goBranch(context, 1),
                ),
                PortalHomeAction(
                  label: 'Embarques',
                  icon: Icons.fact_check_rounded,
                  onTap: () => _goBranch(context, 3),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _MoreActionsPanel(
              onSearchTransport: () => context.push(AppRoutes.searchTransport),
              onEnrollments: () => context.push(AppRoutes.parentEnrollments),
              onProfile: () => context.push(AppRoutes.parentProfile),
            ),
            const SizedBox(height: AppSpacing.xl),
            const AdCardWidget(
              placement: AdPlacements.parentDashboardCard,
              role: AdRole.parent,
            ),
            const SizedBox(height: AppSpacing.md),
            const AdBannerWidget(
              placement: AdPlacements.parentDashboardBanner,
              role: AdRole.parent,
              height: 104,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  static bool _isActiveRoute(Map<String, dynamic> route) {
    final status = (route['status'] ?? '').toString().toLowerCase();
    return status == 'in_progress' ||
        status == 'active' ||
        status == 'started' ||
        status == 'running';
  }

  static void _goBranch(BuildContext context, int index) {
    try {
      StatefulNavigationShell.of(context).goBranch(index);
    } catch (_) {
      context.go(AppRoutes.parentHome);
    }
  }

  static void _openChildDetail(BuildContext context, Child child) {
    context.push(AppRoutes.parentChildDetail, extra: child);
  }
}

class _MoreActionsPanel extends StatefulWidget {
  const _MoreActionsPanel({
    required this.onSearchTransport,
    required this.onEnrollments,
    required this.onProfile,
  });

  final VoidCallback onSearchTransport;
  final VoidCallback onEnrollments;
  final VoidCallback onProfile;

  @override
  State<_MoreActionsPanel> createState() => _MoreActionsPanelState();
}

class _MoreActionsPanelState extends State<_MoreActionsPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Mais ações',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.md),
          DashboardActionGrid(
            crossAxisCount: 3,
            actions: [
              PortalHomeAction(
                label: 'Buscar van',
                icon: Icons.search_rounded,
                onTap: widget.onSearchTransport,
              ),
              PortalHomeAction(
                label: 'Matrículas',
                icon: Icons.how_to_reg_rounded,
                onTap: widget.onEnrollments,
              ),
              PortalHomeAction(
                label: 'Perfil',
                icon: Icons.account_circle_rounded,
                onTap: widget.onProfile,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Counter {
  const _Counter({required this.label, required this.value});

  final String label;
  final int? value;

  bool get hasValue => value != null;
  bool get isZero => value == 0;

  static _Counter fromPage<T>(
    AsyncValue<PaginatedResult<T>> asyncValue,
    int Function(PaginatedResult<T> page) mapper,
  ) {
    return asyncValue.when(
      loading: () => const _Counter(label: '...', value: null),
      error: (error, stackTrace) => const _Counter(label: '--', value: null),
      data: (page) {
        final count = mapper(page);
        return _Counter(label: '$count', value: count);
      },
    );
  }
}
