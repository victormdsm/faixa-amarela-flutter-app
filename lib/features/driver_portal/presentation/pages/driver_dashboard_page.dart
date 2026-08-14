import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/app_error_reporter.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_action_grid.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_metric_grid.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_models.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_section_title.dart';
import '../../../../core/presentation/widgets/e2e_keys.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../../domain/models/route_manifest.dart';
import '../../../ads/domain/ad.dart';
import '../../../ads/presentation/providers/ads_providers.dart';
import '../../../ads/presentation/widgets/ad_card_widget.dart';
import '../providers/driver_portal_providers.dart';
import '../widgets/driver_active_route_card.dart';
import '../widgets/driver_profile_card.dart';
import '../widgets/driver_start_route_card.dart';

class DriverDashboardPage extends ConsumerWidget {
  const DriverDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(driverDashboardControllerProvider);

    Future<void> refresh() async {
      ref.invalidate(adsProvider);
      await ref.read(driverDashboardControllerProvider.notifier).refresh();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: dashboardAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, _) => Scaffold(
          backgroundColor: AppColors.surfaceSoft,
          body: FaixaErrorState(
            message: AppErrorReporter.messageFor(error),
            onRetry: () =>
                ref.read(driverDashboardControllerProvider.notifier).refresh(),
          ),
        ),
        data: (state) {
          final profile = state.profile;
          final activeRoute = state.activeRoute;
          final hasActiveRoute =
              activeRoute != null && activeRoute.status != RouteStatus.finished;
          final totalStops = activeRoute?.stops.length ?? 0;
          final boardedStops = activeRoute?.stops
                  .where((s) => s.status == StopStatus.boarded)
                  .length ??
              0;

          return Scaffold(
            key: E2EKeys.driverHome,
            backgroundColor: AppColors.surfaceSoft,
            appBar: FaixaAppBar.portal(
              actions: [
                IconButton(
                  tooltip: 'Perfil',
                  onPressed: () => context.push(AppRoutes.driverSettings),
                  icon: const Icon(Icons.account_circle_rounded),
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async => refresh(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  DriverProfileCard(profile: profile),
                  const SizedBox(height: AppSpacing.lg),
                  if (hasActiveRoute)
                    DriverActiveRouteCard(
                      route: activeRoute,
                      onAccess: () =>
                          context.push(AppRoutes.driverRouteExecution),
                    )
                  else
                    DriverStartRouteCard(
                      isLoading: dashboardAsync.isLoading,
                      onStart: () => ref
                          .read(driverDashboardControllerProvider.notifier)
                          .startRoute(),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  const DashboardSectionTitle('Resumo operacional'),
                  const SizedBox(height: AppSpacing.md),
                  if (hasActiveRoute)
                    DashboardMetricGrid(
                      metrics: [
                        PortalHomeMetric(
                          label: 'Paradas',
                          value: '$totalStops',
                          icon: Icons.route_rounded,
                        ),
                        PortalHomeMetric(
                          label: 'Embarques',
                          value: '$boardedStops/$totalStops',
                          icon: Icons.fact_check_rounded,
                        ),
                      ],
                    )
                  else
                    const FaixaEmptyState(
                      message: 'Nenhuma rota em andamento.',
                      icon: Icons.route_rounded,
                      subtitle:
                          'O resumo de paradas e embarques aparece aqui durante uma rota.',
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  const DashboardSectionTitle('Ações rápidas'),
                  const SizedBox(height: AppSpacing.md),
                  DashboardActionGrid(
                    crossAxisCount: 2,
                    actions: [
                      // Ambas são abas do shell: trocar de aba (goBranch) em
                      // vez de `go`/`push`, que recriavam o shell e deixavam
                      // a bottom nav fora de sincronia com a tela exibida.
                      PortalHomeAction(
                        key: E2EKeys.driverLookupButton,
                        label: 'Buscar dependente',
                        icon: Icons.person_search_rounded,
                        onTap: () => _goBranch(context, 1),
                      ),
                      PortalHomeAction(
                        label: 'Matrículas',
                        icon: Icons.how_to_reg_rounded,
                        onTap: () => _goBranch(context, 3),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _goBranch(context, 4),
                      icon: const Icon(Icons.notifications_rounded, size: 18),
                      label: const Text('Avisos'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const AdCardWidget(
                    placement: AdPlacements.driverDashboardCard,
                    role: AdRole.driver,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static void _goBranch(BuildContext context, int index) {
    try {
      StatefulNavigationShell.of(context).goBranch(index);
    } catch (_) {
      context.go(AppRoutes.driverHome);
    }
  }
}
