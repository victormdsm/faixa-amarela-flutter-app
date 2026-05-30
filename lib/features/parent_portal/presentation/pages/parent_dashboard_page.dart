import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/faixa_portal_home.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../providers/parent_portal_providers.dart';

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
    }

    final childCount = childrenAsync.when(
      loading: () => '...',
      error: (_, _) => '--',
      data: (page) => '${page.items.length}',
    );
    final routeCount = routesAsync.when(
      loading: () => '...',
      error: (_, _) => '--',
      data: (page) => '${page.items.length}',
    );
    final boardingCount = boardingsAsync.when(
      loading: () => '...',
      error: (_, _) => '--',
      data: (page) => '${page.items.length}',
    );
    final activeRouteCount = routesAsync.when(
      loading: () => '...',
      error: (_, _) => '--',
      data: (page) => '${page.items.where(_isActiveRoute).length}',
    );

    return FaixaPortalHome(
      userName: session?.user.name ?? 'Responsavel',
      roleLabel: 'Bem-vindo',
      statusLabel: activeRouteCount == '0'
          ? 'Nenhuma rota ativa'
          : '$activeRouteCount rota(s) ativa(s)',
      statusActive:
          activeRouteCount != '0' &&
          activeRouteCount != '...' &&
          activeRouteCount != '--',
      onRefresh: refresh,
      onLogout: () => ref.read(appSessionControllerProvider.notifier).clear(),
      metrics: [
        PortalHomeMetric(
          label: 'Dependentes',
          value: childCount,
          icon: Icons.child_care_outlined,
        ),
        PortalHomeMetric(
          label: 'Rotas',
          value: routeCount,
          icon: Icons.route_outlined,
        ),
        PortalHomeMetric(
          label: 'Embarques',
          value: boardingCount,
          icon: Icons.fact_check_outlined,
        ),
        PortalHomeMetric(
          label: 'Ativas',
          value: activeRouteCount,
          icon: Icons.near_me_outlined,
          color: AppColors.success,
        ),
      ],
      actions: [
        PortalHomeAction(
          label: 'Rotas',
          icon: Icons.alt_route_rounded,
          onTap: () => _goBranch(context, 2),
        ),
        PortalHomeAction(
          label: 'Dependentes',
          icon: Icons.child_care_rounded,
          onTap: () => _goBranch(context, 1),
        ),
        PortalHomeAction(
          label: 'Embarques',
          icon: Icons.fact_check_rounded,
          onTap: () => _goBranch(context, 3),
        ),
        PortalHomeAction(
          label: 'Buscar van',
          icon: Icons.search_rounded,
          onTap: () => context.push(AppRoutes.searchTransport),
        ),
        PortalHomeAction(
          label: 'Atualizar',
          icon: Icons.sync_rounded,
          onTap: refresh,
        ),
        PortalHomeAction(
          label: 'Sair',
          icon: Icons.logout_rounded,
          onTap: () => ref.read(appSessionControllerProvider.notifier).clear(),
        ),
      ],
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
    StatefulNavigationShell.of(context).goBranch(index);
  }
}
