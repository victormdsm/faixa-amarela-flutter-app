import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/faixa_portal_home.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../../tracking/presentation/providers/tracking_providers.dart';
import '../providers/driver_portal_providers.dart';

class DriverDashboardPage extends ConsumerWidget {
  const DriverDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionControllerProvider).session;
    final tracking = ref.watch(driverTrackingControllerProvider);
    final clientsAsync = ref.watch(driverClientsProvider);
    final routesAsync = ref.watch(driverRoutesProvider);

    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.login);
      });
    }

    void refresh() {
      ref.invalidate(driverClientsProvider);
      ref.invalidate(driverRoutesProvider);
      ref.invalidate(driverProfileProvider);
    }

    final clientCount = clientsAsync.when(
      loading: () => '...',
      error: (_, _) => '--',
      data: (page) => '${page.items.length}',
    );
    final routeCount = routesAsync.when(
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
      userName: session?.user.name ?? 'Motorista',
      roleLabel: 'Bem-vindo',
      statusLabel: tracking.routeActive
          ? 'Rota em andamento'
          : 'Pronto para comecar',
      statusActive: tracking.routeActive,
      onRefresh: refresh,
      onLogout: () => ref.read(appSessionControllerProvider.notifier).clear(),
      metrics: [
        PortalHomeMetric(
          label: 'Clientes',
          value: clientCount,
          icon: Icons.groups_outlined,
        ),
        PortalHomeMetric(
          label: 'Rotas',
          value: routeCount,
          icon: Icons.route_outlined,
        ),
        PortalHomeMetric(
          label: 'Ativas',
          value: activeRouteCount,
          icon: Icons.near_me_outlined,
          color: AppColors.success,
        ),
        PortalHomeMetric(
          label: 'GPS',
          value: tracking.routeActive
              ? (tracking.foregroundStreaming ? 'Ativo' : 'Fallback')
              : 'Inativo',
          icon: Icons.gps_fixed_rounded,
          color: tracking.routeActive ? AppColors.success : AppColors.muted,
        ),
      ],
      actions: [
        PortalHomeAction(
          label: 'Rotas',
          icon: Icons.alt_route_rounded,
          onTap: () => _goBranch(context, 2),
        ),
        PortalHomeAction(
          label: 'Clientes',
          icon: Icons.family_restroom_rounded,
          onTap: () => _goBranch(context, 1),
        ),
        PortalHomeAction(
          label: 'Novo cliente',
          icon: Icons.person_add_alt_1_rounded,
          onTap: () => context.push(AppRoutes.driverAddClient),
        ),
        PortalHomeAction(
          label: 'Perfil',
          icon: Icons.account_circle_outlined,
          onTap: () => _goBranch(context, 3),
        ),
        PortalHomeAction(
          label: 'Configuracao',
          icon: Icons.tune_rounded,
          onTap: () => context.push(AppRoutes.driverSettings),
        ),
        PortalHomeAction(
          label: 'Ao vivo',
          icon: tracking.socketConnected
              ? Icons.wifi_tethering_rounded
              : Icons.wifi_off_rounded,
          onTap: () => _goBranch(context, 2),
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
