import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/presentation/widgets/faixa_portal_home.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../../driver_portal/presentation/pages/ad_banner_widget.dart';
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
      ref.invalidate(adBannersProvider);
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

    return FaixaPortalHome(
      userName: session?.user.name ?? 'Responsavel',
      roleLabel: 'Bem-vindo',
      statusLabel: activeRouteCount.isZero
          ? 'Nenhuma rota ativa'
          : '${activeRouteCount.label} rota(s) ativa(s)',
      statusActive: activeRouteCount.hasValue && !activeRouteCount.isZero,
      onRefresh: refresh,
      onLogout: () => ref.read(appSessionControllerProvider.notifier).clear(),
      metrics: [
        PortalHomeMetric(
          label: 'Dependentes',
          value: childCount.label,
          icon: Icons.child_care_outlined,
        ),
        PortalHomeMetric(
          label: 'Rotas',
          value: routeCount.label,
          icon: Icons.route_outlined,
        ),
        PortalHomeMetric(
          label: 'Embarques',
          value: boardingCount.label,
          icon: Icons.fact_check_outlined,
        ),
        PortalHomeMetric(
          label: 'Ativas',
          value: activeRouteCount.label,
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
      bottomContent: const AdBannerWidget(height: 104),
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
      // Fora de um shell (ex.: deep link) — fallback para a home do responsavel.
      context.go(AppRoutes.parentHome);
    }
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
