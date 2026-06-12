import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/app_error_reporter.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../domain/models/route_manifest.dart';
import '../../../../domain/repositories/routes_repository.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../../tracking/presentation/providers/tracking_providers.dart';
import '../../../tracking/presentation/state/driver_tracking_controller.dart';
import '../../../tracking/presentation/state/driver_tracking_state.dart';
import '../providers/driver_portal_providers.dart';

// ─────────────────────────────────────────────
// Page — full-screen map layout
// ─────────────────────────────────────────────

class DriverRoutesPage extends ConsumerStatefulWidget {
  const DriverRoutesPage({super.key});

  @override
  ConsumerState<DriverRoutesPage> createState() => _DriverRoutesPageState();
}

class _DriverRoutesPageState extends ConsumerState<DriverRoutesPage> {
  bool _isFinishing = false;

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(driverRoutesProvider);

    DriverTrackingState tracking;
    try {
      tracking = ref.watch(driverTrackingControllerProvider);
    } catch (_) {
      tracking = const DriverTrackingState();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF8BA0B0),
      body: Stack(
        children: [
          // ── Map fills entire body ─────────────────────────────
          Positioned.fill(child: _SafeMapBuilder(tracking: tracking)),

          // ── Top overlay: connection + speed + finish ──────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: _MapTopOverlay(
                  tracking: tracking,
                  isFinishing: _isFinishing,
                  onFinish: _isFinishing ? null : () => _finishRoute(tracking),
                ),
              ),
            ),
          ),

          // ── Bottom sheet: students / saved routes ─────────────
          _BottomSheet(
            tracking: tracking,
            routesAsync: routesAsync,
            onAutoFinish: _finishRoute,
          ),
        ],
      ),
      floatingActionButton: !tracking.routeActive
          ? FloatingActionButton.extended(
              onPressed: () => _openAdhocPlanner(context, ref),
              icon: const Icon(Icons.alt_route_rounded, size: 20),
              label: const Text('Gerar rota'),
            )
          : null,
    );
  }

  Future<void> _finishRoute(DriverTrackingState tracking) async {
    if (_isFinishing) return;
    final routeId = tracking.routeId;
    if (routeId == null || routeId <= 0) return;

    setState(() => _isFinishing = true);
    try {
      await ref.read(driverRoutesRepositoryProvider).finishRoute(routeId);
      await ref
          .read(driverTrackingControllerProvider.notifier)
          .stopRouteTracking(silent: true);
      ref.invalidate(driverRoutesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rota finalizada com sucesso.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorReporter.messageFor(e))));
    } finally {
      if (mounted) setState(() => _isFinishing = false);
    }
  }
}

// ─────────────────────────────────────────────
// Top overlay pills
// ─────────────────────────────────────────────

class _MapTopOverlay extends StatelessWidget {
  const _MapTopOverlay({
    required this.tracking,
    required this.isFinishing,
    this.onFinish,
  });
  final DriverTrackingState tracking;
  final bool isFinishing;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ConnectionPill(tracking: tracking),
        const Spacer(),
        if (tracking.lastSpeedKmh != null) ...[
          _SpeedChip(speedKmh: tracking.lastSpeedKmh!),
          const SizedBox(width: 8),
        ],
        if (tracking.routeActive)
          _FinishBtn(onTap: onFinish, loading: isFinishing),
      ],
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({required this.tracking});
  final DriverTrackingState tracking;

  (Color, String) get _state {
    if (!tracking.routeActive) return (AppColors.muted, 'Aguardando');
    if (tracking.foregroundStreaming && tracking.socketConnected) {
      return (const Color(0xFF22C55E), 'Ao vivo');
    }
    if (tracking.foregroundStreaming) {
      return (const Color(0xFFF59E0B), 'GPS ativo');
    }
    return (const Color(0xFFF59E0B), 'Fallback');
  }

  @override
  Widget build(BuildContext context) {
    final (color, label) = _state;
    return _MapPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({required this.speedKmh});
  final int speedKmh;

  @override
  Widget build(BuildContext context) {
    return _MapPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.speed_rounded, size: 13, color: AppColors.ink),
          const SizedBox(width: 5),
          Text(
            '$speedKmh km/h',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinishBtn extends StatelessWidget {
  const _FinishBtn({this.onTap, this.loading = false});
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: (loading ? AppColors.muted : AppColors.danger).withValues(
            alpha: 0.93,
          ),
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              const Icon(Icons.stop_rounded, size: 13, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              loading ? 'Finalizando...' : 'Finalizar',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPill extends StatelessWidget {
  const _MapPill({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
// Bottom sheet (Google Maps-style)
// ─────────────────────────────────────────────

class _BottomSheet extends StatefulWidget {
  const _BottomSheet({
    required this.tracking,
    required this.routesAsync,
    this.onAutoFinish,
  });
  final DriverTrackingState tracking;
  final AsyncValue<dynamic> routesAsync;
  final Future<void> Function(DriverTrackingState)? onAutoFinish;

  @override
  State<_BottomSheet> createState() => _BottomSheetState();
}

class _BottomSheetState extends State<_BottomSheet> {
  final _sheetController = DraggableScrollableController();
  static const _minSize = 0.12;
  static const _maxSize = 0.88;
  static const _snaps = [0.12, 0.32, 0.65, 0.88];

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  // The drag handle + header sit above the scrollable content, so they are not
  // driven by the sheet's scrollController. Forward their vertical drags to the
  // sheet manually so the user can pull it up/down from the handle.
  void _onHandleDragUpdate(DragUpdateDetails details, double maxHeight) {
    if (!_sheetController.isAttached || maxHeight <= 0) return;
    final delta = details.primaryDelta! / maxHeight;
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
    final routesAsync = widget.routesAsync;
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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x28000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Consumer(
                builder: (context, ref, _) {
                  final students = _studentRouteCards(tracking);
                  return Column(
                    children: [
                      // Drag handle + header (forward drags to the sheet)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: (d) =>
                            _onHandleDragUpdate(d, maxHeight),
                        onVerticalDragEnd: _onHandleDragEnd,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 10,
                                bottom: 4,
                              ),
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
                            // Sheet header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 6, 12, 8),
                              child: Row(
                                children: [
                                  Text(
                                    tracking.routeActive
                                        ? 'Alunos na rota'
                                        : 'Rotas salvas',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.ink,
                                        ),
                                  ),
                                  if (tracking.routeActive &&
                                      students.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.yellowLight,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.full,
                                        ),
                                      ),
                                      child: Text(
                                        '${students.length}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.yellowDark,
                                            ),
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  if (tracking.routeActive) ...[
                                    if (tracking.routeDistanceMeters !=
                                        null) ...[
                                      Icon(
                                        Icons.straighten_rounded,
                                        size: 13,
                                        color: AppColors.slate,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        _formatDistance(
                                          tracking.routeDistanceMeters!,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: AppColors.slate,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    if (tracking.routeEtaSeconds != null) ...[
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 13,
                                        color: AppColors.slate,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        _formatEta(tracking.routeEtaSeconds!),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: AppColors.slate,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ] else ...[
                                    IconButton(
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () =>
                                          ref.invalidate(driverRoutesProvider),
                                      visualDensity: VisualDensity.compact,
                                      color: AppColors.slate,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Content
                      Expanded(
                        child: tracking.routeActive
                            ? _ActiveContent(
                                tracking: tracking,
                                scrollController: scrollController,
                                onAutoFinish: widget.onAutoFinish,
                              )
                            : _SavedRoutesContent(
                                routesAsync: routesAsync,
                                scrollController: scrollController,
                              ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Active route sheet content (students)
// ─────────────────────────────────────────────

class _ActiveContent extends ConsumerStatefulWidget {
  const _ActiveContent({
    required this.tracking,
    required this.scrollController,
    this.onAutoFinish,
  });
  final DriverTrackingState tracking;
  final Future<void> Function(DriverTrackingState)? onAutoFinish;
  final ScrollController scrollController;

  @override
  ConsumerState<_ActiveContent> createState() => _ActiveContentState();
}

class _ActiveContentState extends ConsumerState<_ActiveContent> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final students = _studentRouteCards(widget.tracking);

    if (students.isEmpty) {
      return ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          AppEmptyState(
            message: 'Nenhum aluno na rota atual.',
            icon: Icons.groups_2_outlined,
          ),
        ],
      );
    }

    return ListView.separated(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemCount: students.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index < students.length) {
          final s = students[index];
          return _StudentTile(
            student: s,
            submitting: _submitting,
            routeActive: widget.tracking.routeActive,
            onBoard:
                s.childId != null &&
                    (s.status == _StopStatus.onTheWay ||
                        s.status == _StopStatus.pending)
                ? () => _markBoarded(s.childId!)
                : null,
            onDisembark: s.childId != null && s.status == _StopStatus.boarded
                ? () => _markDisembarked(s.childId!)
                : null,
            onNotifyArrived: s.childId != null
                ? () => _notifyParent(s.childId!, 'arrived')
                : null,
            onNotifyDelayed: s.childId != null
                ? () => _notifyParent(s.childId!, 'delayed')
                : null,
            onRemove: s.childId != null && s.status != _StopStatus.droppedOff
                ? () => _removeStudent(s.childId!, s.name)
                : null,
          );
        }
        return _GeneralAlertSection(tracking: widget.tracking);
      },
    );
  }

  Future<void> _markBoarded(int childId) async {
    await _runAction(
      childId: childId,
      apiCall: (repo, routeId) => repo.markBoarding(routeId, childId),
      onLocal: (ctrl) => ctrl.markClientBoardedLocal(childId),
      msg: 'Aluno embarcou.',
    );
  }

  Future<void> _markDisembarked(int childId) async {
    await _runAction(
      childId: childId,
      apiCall: (repo, routeId) => repo.markDisembarking(routeId, childId),
      onLocal: (ctrl) => ctrl.markClientDisembarkedLocal(childId),
      msg: 'Aluno desembarcou.',
    );

    // Auto-finish when all students have disembarked
    final tracking = ref.read(driverTrackingControllerProvider);
    if (!tracking.routeActive) return;
    final students = _studentRouteCards(tracking);
    if (students.isNotEmpty &&
        students.every((s) => s.status == _StopStatus.droppedOff)) {
      await widget.onAutoFinish?.call(tracking);
    }
  }

  Future<void> _notifyParent(int childId, String type) async {
    await _runAction(
      childId: childId,
      apiCall: (repo, routeId) => repo.notifyParent(routeId, childId, type),
      onLocal: (_) {},
      msg: type == 'arrived'
          ? 'Responsável notificado: cheguei!'
          : 'Responsável notificado: vou atrasar.',
    );
  }

  Future<void> _removeStudent(int childId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover aluno'),
        content: Text('Remover $name da rota? A rota será recalculada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (_submitting) return;

    final routeId = widget.tracking.routeId;
    if (routeId == null || routeId <= 0) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(driverRoutesRepositoryProvider)
          .removeStudent(routeId, childId);
      ref
          .read(driverTrackingControllerProvider.notifier)
          .removeClientLocal(childId);
      await ref
          .read(driverTrackingControllerProvider.notifier)
          .refreshRoutePreviewNow();
      ref.invalidate(driverRoutesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$name removido(a) da rota.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _runAction({
    required int childId,
    required Future<void> Function(RoutesRepository, int) apiCall,
    required void Function(DriverTrackingController) onLocal,
    required String msg,
  }) async {
    if (_submitting) return;
    final routeId = widget.tracking.routeId;
    if (routeId == null || routeId <= 0) return;

    setState(() => _submitting = true);
    try {
      await apiCall(ref.read(driverRoutesRepositoryProvider), routeId);
      onLocal(ref.read(driverTrackingControllerProvider.notifier));
      await ref
          .read(driverTrackingControllerProvider.notifier)
          .refreshRoutePreviewNow();
      ref.invalidate(driverRoutesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

// ─────────────────────────────────────────────
// Saved routes sheet content
// ─────────────────────────────────────────────

class _SavedRoutesContent extends ConsumerWidget {
  const _SavedRoutesContent({
    required this.routesAsync,
    required this.scrollController,
  });
  final AsyncValue<dynamic> routesAsync;
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
        child: AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(driverRoutesProvider),
        ),
      ),
      data: (page) {
        try {
          final items = (page.items as List)
              .where((r) {
                final s = (r['status'] ?? '').toString().toLowerCase().trim();
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
                const AppEmptyState(
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
          return AppErrorState(
            message: 'Erro ao processar rotas: $e',
            onRetry: () => ref.invalidate(driverRoutesProvider),
          );
        }
      },
    );
  }
}

// ─────────────────────────────────────────────
// Safe Map Builder (error boundary)
// ─────────────────────────────────────────────

class _SafeMapBuilder extends StatefulWidget {
  const _SafeMapBuilder({required this.tracking});
  final DriverTrackingState tracking;

  @override
  State<_SafeMapBuilder> createState() => _SafeMapBuilderState();
}

class _SafeMapBuilderState extends State<_SafeMapBuilder> {
  bool _hasError = false;
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_hasError) return _placeholder(context, _error);
    try {
      return _MapLibreRouteMap(
        tracking: widget.tracking,
        onError: (e) {
          if (mounted && !_hasError) {
            setState(() {
              _hasError = true;
              _error = e;
            });
          }
        },
      );
    } catch (e) {
      return _placeholder(context, e);
    }
  }

  static Widget _placeholder(BuildContext context, [Object? error]) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(Icons.map_outlined, size: 28, color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Mapa indisponivel',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.slate,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                '$error',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MapLibre Route Map
// ─────────────────────────────────────────────

class _MapLibreRouteMap extends StatefulWidget {
  const _MapLibreRouteMap({required this.tracking, this.onError});
  final DriverTrackingState tracking;
  final void Function(Object)? onError;

  @override
  State<_MapLibreRouteMap> createState() => _MapLibreRouteMapState();
}

class _MapLibreRouteMapState extends State<_MapLibreRouteMap> {
  MapLibreMapController? _ctrl;
  bool _ready = false;
  bool _followMode = true;

  static const _styleUrl = 'https://tiles.openfreemap.org/styles/liberty';
  static const _defaultCenter = LatLng(-25.5401, -54.5854);

  @override
  void didUpdateWidget(covariant _MapLibreRouteMap old) {
    super.didUpdateWidget(old);
    if (_ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncMap();
      });
    }
  }

  Future<void> _syncMap() async {
    final c = _ctrl;
    if (c == null || !_ready) return;
    try {
      await c.clearLines();
      await c.clearCircles();

      final t = widget.tracking;
      final current = (t.lastLatitude != null && t.lastLongitude != null)
          ? LatLng(t.lastLatitude!, t.lastLongitude!)
          : null;
      final poly = t.routePolyline.map((p) => LatLng(p.lat, p.lng)).toList();
      final stops = t.routeRemainingStops;
      final fallback = [?current, ...stops.map((s) => LatLng(s.lat, s.lng))];
      final display = poly.length >= 2 ? poly : fallback;
      final usingApprox = poly.length < 2 && fallback.length >= 2;

      if (display.length >= 2) {
        await c.addLine(
          LineOptions(
            geometry: display,
            lineColor: '#1A1614',
            lineWidth: 8.0,
            lineOpacity: 0.14,
            lineJoin: 'round',
          ),
        );
        await c.addLine(
          LineOptions(
            geometry: display,
            lineColor: usingApprox ? '#64B5F6' : '#E8B000',
            lineWidth: 5.0,
            lineOpacity: 1.0,
            lineJoin: 'round',
          ),
        );
      }

      for (final s in stops) {
        await c.addCircle(
          CircleOptions(
            geometry: LatLng(s.lat, s.lng),
            circleRadius: 9.0,
            circleColor: '#FFFFFF',
            circleStrokeColor: '#E05252',
            circleStrokeWidth: 2.5,
          ),
        );
      }

      if (current != null) {
        await c.addCircle(
          CircleOptions(
            geometry: current,
            circleRadius: 20.0,
            circleColor: '#E8B000',
            circleOpacity: 0.22,
            circleStrokeWidth: 0,
          ),
        );
        await c.addCircle(
          CircleOptions(
            geometry: current,
            circleRadius: 12.0,
            circleColor: '#E8B000',
            circleStrokeColor: '#1A1614',
            circleStrokeWidth: 2.5,
          ),
        );
      }

      if (_followMode) _animateToDriver();
    } catch (e) {
      widget.onError?.call(e);
    }
  }

  void _animateToDriver() {
    final c = _ctrl;
    if (c == null || !_ready) return;
    final t = widget.tracking;
    if (t.lastLatitude != null && t.lastLongitude != null) {
      c.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(t.lastLatitude!, t.lastLongitude!),
          15.5,
        ),
      );
    }
  }

  void _recenter() {
    final c = _ctrl;
    if (c == null || !_ready) return;
    final t = widget.tracking;
    final current = (t.lastLatitude != null && t.lastLongitude != null)
        ? LatLng(t.lastLatitude!, t.lastLongitude!)
        : null;
    final poly = t.routePolyline.map((p) => LatLng(p.lat, p.lng)).toList();
    final stops = t.routeRemainingStops
        .map((s) => LatLng(s.lat, s.lng))
        .toList();
    final all = [?current, ...poly, ...stops];
    final center = _avgLatLng(all) ?? current ?? _defaultCenter;
    final zoom = poly.length >= 2 ? 13.4 : 16.2;
    c.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: center, zoom: zoom),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tracking;
    final current = (t.lastLatitude != null && t.lastLongitude != null)
        ? LatLng(t.lastLatitude!, t.lastLongitude!)
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep buttons above the sheet's initial snap position (30% active / 20% idle)
        final buttonBottom =
            constraints.maxHeight * (t.routeActive ? 0.36 : 0.26) + 8;

        return Stack(
          children: [
            MapLibreMap(
              styleString: _styleUrl,
              initialCameraPosition: CameraPosition(
                target: current ?? _defaultCenter,
                zoom: 14.0,
              ),
              onMapCreated: (c) => _ctrl = c,
              onStyleLoadedCallback: () {
                setState(() => _ready = true);
                _syncMap();
              },
              compassEnabled: false,
              myLocationEnabled: false,
              tiltGesturesEnabled: false,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: false,
              onMapClick: (_, _) {
                if (_followMode) setState(() => _followMode = false);
              },
            ),

            // Map controls (right side, dynamically above bottom sheet)
            Positioned(
              right: 12,
              bottom: buttonBottom,
              child: Column(
                children: [
                  _MapBtn(
                    icon: Icons.add_rounded,
                    onPressed: !_ready
                        ? null
                        : () => _ctrl?.animateCamera(CameraUpdate.zoomIn()),
                  ),
                  const SizedBox(height: 6),
                  _MapBtn(
                    icon: Icons.remove_rounded,
                    onPressed: !_ready
                        ? null
                        : () => _ctrl?.animateCamera(CameraUpdate.zoomOut()),
                  ),
                  const SizedBox(height: 6),
                  _MapBtn(
                    icon: _followMode
                        ? Icons.my_location_rounded
                        : Icons.location_searching_rounded,
                    active: _followMode,
                    onPressed: !_ready
                        ? null
                        : () {
                            setState(() => _followMode = true);
                            _animateToDriver();
                          },
                  ),
                  const SizedBox(height: 6),
                  _MapBtn(
                    icon: Icons.fit_screen_rounded,
                    onPressed: !_ready ? null : _recenter,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MapBtn extends StatelessWidget {
  const _MapBtn({
    required this.icon,
    required this.onPressed,
    this.active = false,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? AppColors.yellow.withValues(alpha: 0.9)
          : AppColors.surface.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(AppRadius.md),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onPressed,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            color: active ? AppColors.ink : AppColors.ink,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Students on Route
// ─────────────────────────────────────────────

enum _StopStatus { pending, onTheWay, boarded, droppedOff }

class _StudentCard {
  const _StudentCard({
    required this.clientId,
    required this.childId,
    required this.name,
    required this.sequence,
    required this.status,
    this.pickupLabel,
    this.dropoffLabel,
    this.nextAction,
  });
  final int? clientId;
  final int? childId;
  final String name;
  final int? sequence;
  final _StopStatus status;
  final String? pickupLabel;
  final String? dropoffLabel;
  final String? nextAction;
}

class _StudentTile extends StatefulWidget {
  const _StudentTile({
    required this.student,
    required this.submitting,
    required this.routeActive,
    this.onBoard,
    this.onDisembark,
    this.onNotifyArrived,
    this.onNotifyDelayed,
    this.onRemove,
  });
  final _StudentCard student;
  final bool submitting;
  final bool routeActive;
  final VoidCallback? onBoard;
  final VoidCallback? onDisembark;
  final VoidCallback? onNotifyArrived;
  final VoidCallback? onNotifyDelayed;
  final VoidCallback? onRemove;

  @override
  State<_StudentTile> createState() => _StudentTileState();
}

class _StudentTileState extends State<_StudentTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final (label, color) = switch (student.status) {
      _StopStatus.onTheWay => ('A caminho', const Color(0xFF1565C0)),
      _StopStatus.boarded => ('Embarcado', const Color(0xFF0A7E52)),
      _StopStatus.droppedOff => ('Desembarcado', AppColors.slate),
      _StopStatus.pending => ('Pendente', AppColors.slate),
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (student.sequence != null) ...[
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            '${student.sequence}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: Text(
                          student.name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                        color: AppColors.slate,
                      ),
                    ],
                  ),
                  if (student.pickupLabel != null ||
                      student.dropoffLabel != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      [
                        if (student.pickupLabel != null)
                          'Embarque: ${student.pickupLabel}',
                        if (student.dropoffLabel != null)
                          'Destino: ${student.dropoffLabel}',
                      ].join(' · '),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      FilledButton.tonal(
                        onPressed: widget.submitting || !widget.routeActive
                            ? null
                            : widget.onBoard,
                        child: const Text('Embarcou'),
                      ),
                      OutlinedButton(
                        onPressed: widget.submitting || !widget.routeActive
                            ? null
                            : widget.onDisembark,
                        child: const Text('Desembarcou'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Notificar responsável',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionChip(
                          icon: Icons.location_on_rounded,
                          label: 'Cheguei',
                          color: const Color(0xFF0A7E52),
                          enabled: !widget.submitting && widget.routeActive,
                          onTap: widget.onNotifyArrived,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _ActionChip(
                          icon: Icons.schedule_rounded,
                          label: 'Vou atrasar',
                          color: const Color(0xFFF9A825),
                          enabled: !widget.submitting && widget.routeActive,
                          onTap: widget.onNotifyDelayed,
                        ),
                      ),
                    ],
                  ),
                  if (widget.onRemove != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: widget.submitting ? null : widget.onRemove,
                        icon: const Icon(Icons.person_remove_rounded, size: 18),
                        label: const Text('Remover da rota'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(
                            color: AppColors.danger,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = enabled ? color : AppColors.slate.withValues(alpha: 0.5);
    return Material(
      color: fg.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

// ─────────────────────────────────────────────
// General Alert Section
// ─────────────────────────────────────────────

class _GeneralAlertSection extends ConsumerStatefulWidget {
  const _GeneralAlertSection({required this.tracking});
  final DriverTrackingState tracking;

  @override
  ConsumerState<_GeneralAlertSection> createState() =>
      _GeneralAlertSectionState();
}

class _GeneralAlertSectionState extends ConsumerState<_GeneralAlertSection> {
  bool _sending = false;

  static const _alertTypes = <(String, String, IconData, Color)>[
    ('breakdown', 'Van quebrou', Icons.car_crash_rounded, Color(0xFFD32F2F)),
    ('flat_tire', 'Pneu furou', Icons.tire_repair_rounded, Color(0xFFF57C00)),
    ('accident', 'Acidente', Icons.warning_amber_rounded, Color(0xFFD32F2F)),
    ('general', 'Atraso geral', Icons.schedule_rounded, Color(0xFFF9A825)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.campaign_rounded,
                size: 20,
                color: Color(0xFFF57C00),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Alerta geral para todos os responsáveis',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _alertTypes.map((t) {
              final (type, label, icon, color) = t;
              return _AlertTypeButton(
                icon: icon,
                label: label,
                color: color,
                enabled: !_sending,
                onTap: () => _sendAlert(type, label),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _sendAlert(String type, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enviar alerta geral?'),
        content: Text(
          'Todos os responsáveis dos alunos na rota serão notificados: "$label".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text('Enviar alerta'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final routeId = widget.tracking.routeId;
    if (routeId == null || routeId <= 0) return;

    setState(() => _sending = true);
    try {
      await ref.read(driverRoutesRepositoryProvider).alertAll(routeId, type);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alerta enviado aos responsáveis.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _AlertTypeButton extends StatelessWidget {
  const _AlertTypeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? color.withValues(alpha: 0.10)
          : Colors.grey.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.md,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: enabled ? color : AppColors.slate),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: enabled ? color : AppColors.slate,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Saved Route Card
// ─────────────────────────────────────────────

class _SavedRouteCard extends ConsumerWidget {
  const _SavedRouteCard({required this.route});
  final Map<String, dynamic> route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeId = (route['id'] as num?)?.toInt() ?? 0;
    final name = (route['name'] ?? 'Rota #$routeId').toString();
    final status = (route['status'] ?? 'N/A').toString();
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
                    routeId <= 0 || (!isThisRoute && status != 'in_progress')
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

  int _resolveBoardingsCount(Map<String, dynamic> route) {
    if (route['boardings_count'] is num) {
      return (route['boardings_count'] as num).toInt();
    }
    final manifest = route['manifest'];
    if (manifest is Map) {
      final document = manifest['document'];
      if (document is Map) {
        final children = document['children'];
        if (children is List) return children.length;
      }
      final stops = manifest['stops'];
      if (stops is List) return stops.length;
    }
    return 0;
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    bool start,
  ) async {
    try {
      final routeId = (route['id'] as num?)?.toInt() ?? 0;
      final session = ref.read(appSessionControllerProvider).session;
      if (session == null) throw ApiException(message: 'Sessao expirada.');
      final repo = ref.read(driverRoutesRepositoryProvider);
      final ctrl = ref.read(driverTrackingControllerProvider.notifier);

      if (start) {
        final response = await repo.startRoute();
        if (!context.mounted) return;
        await _startTrackingFromResponse(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(start ? 'Rota iniciada.' : 'Rota finalizada.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorReporter.messageFor(e))));
    }
  }
}

// ─────────────────────────────────────────────
// Adhoc Route Planner
// ─────────────────────────────────────────────

Future<void> _openAdhocPlanner(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(driverRoutesRepositoryProvider);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => FutureBuilder<RoutePlanningOptions>(
      future: repo.getPlanningOptions(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppErrorReporter.messageFor(
                snapshot.error ?? Exception('Falha ao carregar dados da rota.'),
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        final options =
            snapshot.data ?? const RoutePlanningOptions(vans: [], children: []);
        return _AdhocPlannerContent(
          options: options,
          onStart: () async {
            final response = await repo.startRoute();
            if (!context.mounted) return;
            await _startTrackingFromResponse(context, ref, response);
            if (!context.mounted) return;
            ref.invalidate(driverRoutesProvider);
          },
        );
      },
    ),
  );
}

class _AdhocPlannerContent extends StatefulWidget {
  const _AdhocPlannerContent({required this.options, required this.onStart});
  final RoutePlanningOptions options;
  final Future<void> Function() onStart;

  @override
  State<_AdhocPlannerContent> createState() => _AdhocPlannerContentState();
}

class _AdhocPlannerContentState extends State<_AdhocPlannerContent> {
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final children = widget.options.children;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Iniciar rota',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'A rota sera criada com base nos alunos ativos vinculados ao seu veiculo.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: children.isEmpty
                ? const Center(
                    child: Text('Nenhum aluno ativo vinculado no momento.'),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: children.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) => _buildChildItem(children[i]),
                  ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: Text(_busy ? 'Iniciando...' : 'Iniciar rota'),
          ),
        ],
      ),
    );
  }

  Widget _buildChildItem(PlanningChild child) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            child.name,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (child.schoolName.isNotEmpty)
            Text(
              'Escola: ${child.schoolName}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (child.address.isNotEmpty)
            Text(
              'Endereco: ${child.address}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onStart();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rota iniciada.')));
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }
}

// ─────────────────────────────────────────────
// Shared tracking helpers
// ─────────────────────────────────────────────

Future<void> _startTrackingFromResponse(
  BuildContext context,
  WidgetRef ref,
  RouteManifest manifest, {
  int? fallbackRouteId,
}) async {
  final session = ref.read(appSessionControllerProvider).session;
  if (session == null) throw ApiException(message: 'Sessao expirada.');

  final routeId = manifest.id > 0 ? manifest.id : fallbackRouteId ?? 0;
  final manifestId = manifest.id.toString();
  final vanId = manifest.vanId;

  if (routeId <= 0 || manifestId.isEmpty) {
    throw ApiException(
      message: 'Backend nao retornou dados suficientes para iniciar.',
    );
  }
  if (vanId <= 0) {
    throw ApiException(message: 'Van ID invalido retornado pelo backend.');
  }

  final ctrl = ref.read(driverTrackingControllerProvider.notifier);
  final started = await ctrl.startRouteTracking(
    session: session,
    routeId: routeId,
    routeManifestId: manifestId,
    vanId: vanId,
  );
  if (!started) {
    throw ApiException(
      message:
          'Nao foi possivel iniciar o rastreamento. Verifique as permissoes do aparelho.',
    );
  }

  // O preview da rota sera preenchido pelo primeiro recalculo de tracking.
}

List<_StudentCard> _studentRouteCards(DriverTrackingState tracking) {
  final planned = tracking.routePlannedStops;
  if (planned.isEmpty) return const [];

  final nextKey = tracking.routeRemainingStops.isNotEmpty
      ? _keyOf(tracking.routeRemainingStops.first)
      : null;

  final grouped = <String, List<DriverTrackingStopPoint>>{};
  for (final stop in planned) {
    if ((stop.childId ?? 0) <= 0) continue;
    grouped.putIfAbsent(_keyOf(stop), () => []).add(stop);
  }

  final result = <_StudentCard>[];
  for (final entry in grouped.entries) {
    final stops = [...entry.value]
      ..sort((a, b) => (a.sequence ?? 9999).compareTo(b.sequence ?? 9999));
    final pickup = stops
        .where((s) => (s.type ?? '').startsWith('pickup'))
        .cast<DriverTrackingStopPoint?>()
        .firstWhere((_) => true, orElse: () => null);
    final dropoff = stops
        .where((s) => (s.type ?? '').startsWith('dropoff'))
        .cast<DriverTrackingStopPoint?>()
        .firstWhere((_) => true, orElse: () => null);
    final anyDelivered = stops.any(
      (s) => s.status.toLowerCase() == 'delivered',
    );
    final anyPicked = stops.any((s) => s.status.toLowerCase() == 'picked_up');
    final status = anyDelivered
        ? _StopStatus.droppedOff
        : anyPicked
        ? _StopStatus.boarded
        : (entry.key == nextKey ? _StopStatus.onTheWay : _StopStatus.pending);
    result.add(
      _StudentCard(
        clientId: stops.first.clientId,
        childId: stops.first.childId,
        name: stops.first.name ?? 'Aluno',
        sequence: stops.first.sequence,
        status: status,
        pickupLabel: pickup?.name,
        dropoffLabel: dropoff?.name,
        nextAction: switch (status) {
          _StopStatus.onTheWay || _StopStatus.pending => 'Coletar',
          _StopStatus.boarded => 'Destino',
          _StopStatus.droppedOff => 'Concluido',
        },
      ),
    );
  }
  result.sort((a, b) => (a.sequence ?? 9999).compareTo(b.sequence ?? 9999));
  return result;
}

String _keyOf(DriverTrackingStopPoint s) {
  if ((s.childId ?? 0) > 0) return 'ch:${s.childId}';
  if ((s.clientId ?? 0) > 0) return 'c:${s.clientId}';
  return 's:${s.id ?? s.name ?? s.sequence ?? ''}';
}

LatLng? _avgLatLng(List<LatLng> pts) {
  if (pts.isEmpty) return null;
  var lat = 0.0, lng = 0.0;
  for (final p in pts) {
    lat += p.latitude;
    lng += p.longitude;
  }
  return LatLng(lat / pts.length, lng / pts.length);
}

String _formatEta(int seconds) {
  if (seconds < 60) return '${seconds}s';
  if (seconds < 3600) return '${(seconds / 60).round()} min';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  return '${h}h ${m}min';
}

String _formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}
