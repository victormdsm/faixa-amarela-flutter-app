import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/app_error_reporter.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../../core/presentation/widgets/safe_bottom_inset.dart';
import '../../../../domain/models/route_manifest.dart';
import '../providers/driver_portal_providers.dart';
import '../widgets/bulk_disembark_dialog.dart';
import '../widgets/route_execution_stats_header.dart';
import '../widgets/route_execution_stop_card.dart';

class DriverRouteExecutionPage extends ConsumerWidget {
  const DriverRouteExecutionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeAsync = ref.watch(driverRouteControllerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.surfaceSoft,
        appBar: FaixaAppBar.screen(
          title: 'Execução da rota',
          actions: [
            IconButton(
              onPressed: () =>
                  ref.read(driverRouteControllerProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: routeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => FaixaErrorState(
            message: AppErrorReporter.messageFor(error),
            onRetry: () =>
                ref.read(driverRouteControllerProvider.notifier).refresh(),
          ),
          data: (route) {
            if (route == null) {
              return FaixaEmptyState(
                message: 'Nenhuma rota ativa no momento.',
                icon: Icons.route_rounded,
                actionLabel: 'Voltar ao início',
                onAction: () => context.go(AppRoutes.driverHome),
              );
            }
            return _RouteBody(route: route);
          },
        ),
      ),
    );
  }
}

class _RouteBody extends ConsumerWidget {
  const _RouteBody({required this.route});

  final RouteManifest route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Stops de escola (type "school") são a âncora da viagem — aparecem no
    // mapa, mas não são paradas acionáveis (sem embarque/desembarque/
    // remoção), então saem da lista e dos contadores.
    final boardingStops = route.stops
        .where((s) => !s.isSchoolAnchor)
        .toList(growable: false);
    final boardedCount = boardingStops
        .where((s) => s.status == StopStatus.boarded)
        .length;
    final pendingCount = boardingStops
        .where((s) => s.status == StopStatus.pending)
        .length;

    return Column(
      children: [
        RouteExecutionStatsHeader(
          totalStops: boardingStops.length,
          boardedCount: boardedCount,
          pendingCount: pendingCount,
        ),
        if (boardedCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showBulkDisembarkDialog(context, ref),
                icon: const Icon(Icons.school_rounded),
                label: const Text('Entregar todos na escola'),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: boardingStops.isEmpty
              ? const FaixaEmptyState(
                  message: 'Nenhuma parada nesta rota.',
                  icon: Icons.route_rounded,
                )
              : ListView.builder(
                  // Tela empilhada (sem bottom nav): o último card ficava
                  // embaixo da barra de navegação do sistema.
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    safeBottomInset(context),
                  ),
                  itemCount: boardingStops.length,
                  itemBuilder: (context, index) {
                    final stop = boardingStops[index];
                    return RouteExecutionStopCard(
                      stop: stop,
                      showRemoveButton: true,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showBulkDisembarkDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showBulkDisembarkDialog(
      context,
      route: route,
      onConfirm: () => ref
          .read(driverRouteControllerProvider.notifier)
          .bulkDisembarkAtSchool(_resolveSchoolId()),
    );
  }

  int _resolveSchoolId() {
    final firstStopWithSchool = route.stops
        .where((s) => s.schoolId != null && s.schoolId! > 0)
        .firstOrNull;
    return firstStopWithSchool?.schoolId ?? 0;
  }
}
