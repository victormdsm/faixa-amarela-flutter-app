import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/app_error_reporter.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../domain/models/driver_route_summary.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../../tracking/presentation/providers/tracking_providers.dart';
import '../../../tracking/presentation/state/driver_tracking_state.dart';
import '../providers/driver_portal_providers.dart';
import 'route_format_helpers.dart';
import 'route_passengers_list.dart';
import 'route_tracking_helpers.dart';

/// Bottom sheet que exibe a lista de alunos na rota ativa ou as rotas salvas.
class RouteBottomSheet extends StatefulWidget {
  const RouteBottomSheet({
    super.key,
    required this.tracking,
    required this.routesAsync,
    this.onAutoFinish,
    this.onRefresh,
  });

  final DriverTrackingState tracking;
  final AsyncValue<PaginatedResult<DriverRouteSummary>> routesAsync;
  final Future<void> Function(DriverTrackingState)? onAutoFinish;
  final VoidCallback? onRefresh;

  @override
  State<RouteBottomSheet> createState() => _RouteBottomSheetState();
}

class _RouteBottomSheetState extends State<RouteBottomSheet> {
  final _sheetController = DraggableScrollableController();
  static const _minSize = 0.12;
  static const _maxSize = 0.88;
  static const _snaps = [0.12, 0.32, 0.65, 0.88];

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _onHandleDragUpdate(DragUpdateDetails details, double maxHeight) {
    if (!_sheetController.isAttached || maxHeight <= 0) return;
    final primaryDelta = details.primaryDelta;
    if (primaryDelta == null) return;
    final delta = primaryDelta / maxHeight;
    final next = (_sheetController.size - delta).clamp(_minSize, _maxSize);
    _sheetController.jumpTo(next);
  }

  void _onHandleDragEnd(DragEndDetails details) {
    if (!_sheetController.isAttached) return;
    final current = _sheetController.size;
    var target = _snaps.first;
    var bestDelta = double.infinity;
    for (final s in _snaps) {
      final d = (s - current).abs();
      if (d < bestDelta) {
        bestDelta = d;
        target = s;
      }
    }
    _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tracking = widget.tracking;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        return DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: tracking.routeActive ? 0.32 : 0.45,
          minChildSize: _minSize,
          maxChildSize: _maxSize,
          snap: true,
          snapSizes: _snaps,
          builder: (ctx, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.16),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (d) =>
                        _onHandleDragUpdate(d, maxHeight),
                    onVerticalDragEnd: _onHandleDragEnd,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 4),
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                          ),
                        ),
                        _SheetHeader(
                          tracking: tracking,
                          onRefresh: widget.onRefresh,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: tracking.routeActive
                        ? RoutePassengersList(
                            tracking: tracking,
                            scrollController: scrollController,
                            onAutoFinish: widget.onAutoFinish,
                          )
                        : _SavedRoutesContent(
                            routesAsync: widget.routesAsync,
                            scrollController: scrollController,
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.tracking, this.onRefresh});

  final DriverTrackingState tracking;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final students = buildStudentRouteCards(tracking);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 8),
      child: Row(
        children: [
          Text(
            tracking.routeActive ? 'Alunos na rota' : 'Rotas salvas',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          if (tracking.routeActive && students.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.yellowLight,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '${students.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.yellowDark,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (tracking.routeActive) ...[
            if (tracking.routeDistanceMeters != null) ...[
              const Icon(
                Icons.straighten_rounded,
                size: 13,
                color: AppColors.slate,
              ),
              const SizedBox(width: 3),
              Text(
                formatDistance(tracking.routeDistanceMeters!),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.slate,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
            ],
            if (tracking.routeEtaSeconds != null) ...[
              const Icon(
                Icons.schedule_rounded,
                size: 13,
                color: AppColors.slate,
              ),
              const SizedBox(width: 3),
              Text(
                formatEta(tracking.routeEtaSeconds!),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.slate,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ] else
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              onPressed: onRefresh,
              visualDensity: VisualDensity.compact,
              color: AppColors.slate,
            ),
        ],
      ),
    );
  }
}

class _SavedRoutesContent extends ConsumerWidget {
  const _SavedRoutesContent({
    required this.routesAsync,
    required this.scrollController,
  });

  final AsyncValue<PaginatedResult<DriverRouteSummary>> routesAsync;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return routesAsync.when(
      loading: () => const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: FaixaErrorState(
          message: AppErrorReporter.messageFor(e),
          onRetry: () => ref.invalidate(driverRoutesProvider),
        ),
      ),
      data: (page) {
        try {
          final items = page.items
              .where((r) {
                final s = r.status.toLowerCase().trim();
                return s != 'finished' && s != 'finalized' && s != 'completed';
              })
              .toList(growable: false);

          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              100,
            ),
            children: [
              if (items.isEmpty)
                const FaixaEmptyState(
                  message: 'Nenhuma rota encontrada.',
                  icon: Icons.route_outlined,
                  subtitle: 'Gere uma rota para comecar.',
                )
              else
                for (final route in items) ...[
                  _SavedRouteCard(route: route),
                  const SizedBox(height: AppSpacing.sm),
                ],
            ],
          );
        } catch (e) {
          return FaixaErrorState(
            message: AppErrorReporter.messageFor(e),
            onRetry: () => ref.invalidate(driverRoutesProvider),
          );
        }
      },
    );
  }
}

class _SavedRouteCard extends ConsumerWidget {
  const _SavedRouteCard({required this.route});
  final DriverRouteSummary route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeId = route.id;
    final name = 'Rota #$routeId';
    final status = route.status;
    final boardingsCount = _resolveBoardingsCount(route).toString();
    final tracking = ref.watch(driverTrackingControllerProvider);
    final isThisRoute = tracking.routeActive && tracking.routeId == routeId;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isThisRoute ? AppColors.ink : AppColors.border,
          width: isThisRoute ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (isThisRoute) const _StatusPill(label: 'Ativa', active: true),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Status: $status · Embarques: $boardingsCount',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.tonal(
                onPressed: routeId <= 0
                    ? null
                    : () => _handleAction(context, ref, true),
                child: const Text('Iniciar'),
              ),
              OutlinedButton(
                onPressed:
                    routeId <= 0 ||
                        (!isThisRoute &&
                            status != 'in_progress' &&
                            status != 'active')
                    ? null
                    : () => _handleAction(context, ref, false),
                child: const Text('Finalizar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _resolveBoardingsCount(DriverRouteSummary route) {
    if (route.boardingsCount > 0) return route.boardingsCount;
    final manifest = route.manifest;
    if (manifest == null) return 0;
    final document = manifest['document'];
    if (document is Map) {
      final children = document['children'];
      if (children is List) return children.length;
    }
    final stops = manifest['stops'];
    if (stops is List) return stops.length;
    return 0;
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    bool start,
  ) async {
    try {
      final routeId = route.id;
      final session = ref.read(appSessionControllerProvider).session;
      if (session == null) throw ApiException(message: 'Sessão expirada.');
      final repo = ref.read(driverRoutesRepositoryProvider);
      final ctrl = ref.read(driverTrackingControllerProvider.notifier);

      if (start) {
        final response = await repo.startRoute();
        if (!context.mounted) return;
        await startTrackingFromResponse(
          context,
          ref,
          response,
          fallbackRouteId: routeId,
        );
        if (!context.mounted) return;
      } else {
        if (routeId <= 0) throw ApiException(message: 'Rota invalida.');
        await repo.finishRoute(routeId);
        await ctrl.stopRouteTracking(silent: true);
      }
      ref.invalidate(driverRoutesProvider);
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        message: start ? 'Rota iniciada.' : 'Rota finalizada.',
        type: AppFeedbackType.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        message: AppErrorReporter.messageFor(e),
        type: AppFeedbackType.error,
      );
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: active ? AppColors.success : AppColors.danger,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
