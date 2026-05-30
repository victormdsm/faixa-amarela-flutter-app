import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../../tracking/presentation/providers/tracking_providers.dart';
import '../../../tracking/presentation/state/driver_tracking_controller.dart';
import '../../../tracking/presentation/state/driver_tracking_state.dart';
import '../../data/driver_portal_repository.dart';
import '../providers/driver_portal_providers.dart';

// ─────────────────────────────────────────────
// Page — full-screen map layout
// ─────────────────────────────────────────────

class DriverRoutesPage extends ConsumerWidget {
  const DriverRoutesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          Positioned.fill(
            child: _SafeMapBuilder(tracking: tracking),
          ),

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
                  onFinish: () => _finishRoute(context, ref, tracking),
                ),
              ),
            ),
          ),

          // ── Bottom sheet: students / saved routes ─────────────
          _BottomSheet(tracking: tracking, routesAsync: routesAsync),
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

  Future<void> _finishRoute(
    BuildContext context,
    WidgetRef ref,
    DriverTrackingState tracking,
  ) async {
    final routeId = tracking.routeId;
    if (routeId == null || routeId <= 0) return;
    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) return;
    try {
      await ref
          .read(driverPortalRepositoryProvider)
          .finishRoute(session.authorizationHeader, routeId);
      await ref
          .read(driverTrackingControllerProvider.notifier)
          .stopRouteTracking(silent: true);
      ref.invalidate(driverRoutesProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rota finalizada com sucesso.')),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }
}

// ─────────────────────────────────────────────
// Top overlay pills
// ─────────────────────────────────────────────

class _MapTopOverlay extends StatelessWidget {
  const _MapTopOverlay({required this.tracking, required this.onFinish});
  final DriverTrackingState tracking;
  final VoidCallback onFinish;

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
          _FinishBtn(onTap: onFinish),
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
    if (tracking.foregroundStreaming) return (const Color(0xFFF59E0B), 'GPS ativo');
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
  const _FinishBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.93),
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stop_rounded, size: 13, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              'Finalizar',
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
          BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
// Bottom sheet (Google Maps-style)
// ─────────────────────────────────────────────

class _BottomSheet extends StatelessWidget {
  const _BottomSheet({required this.tracking, required this.routesAsync});
  final DriverTrackingState tracking;
  final AsyncValue<dynamic> routesAsync;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: tracking.routeActive ? 0.30 : 0.20,
      minChildSize: 0.12,
      maxChildSize: 0.88,
      snap: true,
      snapSizes: const [0.12, 0.32, 0.65, 0.88],
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
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 4),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  ),
                  // Sheet header
                  Padding(
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
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
                            Icon(Icons.straighten_rounded, size: 13, color: AppColors.slate),
                            const SizedBox(width: 3),
                            Text(
                              _formatDistance(tracking.routeDistanceMeters!),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.slate,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (tracking.routeEtaSeconds != null) ...[
                            Icon(Icons.schedule_rounded, size: 13, color: AppColors.slate),
                            const SizedBox(width: 3),
                            Text(
                              _formatEta(tracking.routeEtaSeconds!),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.slate,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ] else ...[
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            onPressed: () => ref.invalidate(driverRoutesProvider),
                            visualDensity: VisualDensity.compact,
                            color: AppColors.slate,
                          ),
                        ],
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
  }
}

// ─────────────────────────────────────────────
// Active route sheet content (students)
// ─────────────────────────────────────────────

class _ActiveContent extends ConsumerStatefulWidget {
  const _ActiveContent({
    required this.tracking,
    required this.scrollController,
  });
  final DriverTrackingState tracking;
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
            onBoard: s.clientId != null &&
                    (s.status == _StopStatus.onTheWay ||
                        s.status == _StopStatus.pending)
                ? () => _markBoarded(s.clientId!)
                : null,
            onDisembark: s.clientId != null && s.status == _StopStatus.boarded
                ? () => _markDisembarked(s.clientId!)
                : null,
            onNotifyArrived: s.clientId != null
                ? () => _notifyParent(s.clientId!, 'arrived')
                : null,
            onNotifyDelayed: s.clientId != null
                ? () => _notifyParent(s.clientId!, 'delayed')
                : null,
            onRemove: s.clientId != null && s.status != _StopStatus.droppedOff
                ? () => _removeStudent(s.clientId!, s.name)
                : null,
          );
        }
        return _GeneralAlertSection(tracking: widget.tracking);
      },
    );
  }

  Future<void> _markBoarded(int clientId) async {
    await _runAction(
      clientId: clientId,
      apiCall: (repo, auth, routeId) =>
          repo.markBoarding(auth, routeId, clientId: clientId),
      onLocal: (ctrl) => ctrl.markClientBoardedLocal(clientId),
      msg: 'Aluno embarcou.',
    );
  }

  Future<void> _markDisembarked(int clientId) async {
    await _runAction(
      clientId: clientId,
      apiCall: (repo, auth, routeId) =>
          repo.markDisembarking(auth, routeId, clientId: clientId),
      onLocal: (ctrl) => ctrl.markClientDisembarkedLocal(clientId),
      msg: 'Aluno desembarcou.',
    );
  }

  Future<void> _notifyParent(int clientId, String type) async {
    await _runAction(
      clientId: clientId,
      apiCall: (repo, auth, routeId) =>
          repo.notifyParent(auth, routeId, clientId: clientId, type: type),
      onLocal: (_) {},
      msg: type == 'arrived'
          ? 'Responsável notificado: cheguei!'
          : 'Responsável notificado: vou atrasar.',
    );
  }

  Future<void> _removeStudent(int clientId, String name) async {
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
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (_submitting) return;

    final routeId = widget.tracking.routeId;
    final session = ref.read(appSessionControllerProvider).session;
    if (routeId == null || routeId <= 0 || session == null) return;

    setState(() => _submitting = true);
    try {
      await ref.read(driverPortalRepositoryProvider).removeStudentFromRoute(
            session.authorizationHeader,
            routeId,
            clientId: clientId,
            lat: widget.tracking.lastLatitude,
            lng: widget.tracking.lastLongitude,
          );
      ref.read(driverTrackingControllerProvider.notifier).removeClientLocal(clientId);
      await ref
          .read(driverTrackingControllerProvider.notifier)
          .refreshRoutePreviewNow();
      ref.invalidate(driverRoutesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name removido(a) da rota.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _runAction({
    required int clientId,
    required Future<Map<String, dynamic>> Function(
      DriverPortalRepository,
      String,
      int,
    ) apiCall,
    required void Function(DriverTrackingController) onLocal,
    required String msg,
  }) async {
    if (_submitting) return;
    final routeId = widget.tracking.routeId;
    final session = ref.read(appSessionControllerProvider).session;
    if (routeId == null || routeId <= 0 || session == null) return;

    setState(() => _submitting = true);
    try {
      await apiCall(
        ref.read(driverPortalRepositoryProvider),
        session.authorizationHeader,
        routeId,
      );
      onLocal(ref.read(driverTrackingControllerProvider.notifier));
      await ref
          .read(driverTrackingControllerProvider.notifier)
          .refreshRoutePreviewNow();
      ref.invalidate(driverRoutesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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

          if (items.isEmpty) {
            return ListView(
              controller: scrollController,
              children: const [
                AppEmptyState(
                  message: 'Nenhuma rota encontrada.',
                  icon: Icons.route_outlined,
                  subtitle: 'Gere uma rota para comecar.',
                ),
              ],
            );
          }

          return ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              100,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) =>
                _SavedRouteCard(route: items[index]),
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
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.muted,
                ),
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
    final stops = t.routeRemainingStops.map((s) => LatLng(s.lat, s.lng)).toList();
    final all = [?current, ...poly, ...stops];
    final center = _avgLatLng(all) ?? current ?? _defaultCenter;
    final zoom = poly.length >= 2 ? 13.4 : 16.2;
    c.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: center, zoom: zoom)),
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
  const _MapBtn({required this.icon, required this.onPressed, this.active = false});
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
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: Text(
                          student.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
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
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                  if (student.pickupLabel != null || student.dropoffLabel != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      [
                        if (student.pickupLabel != null)
                          'Embarque: ${student.pickupLabel}',
                        if (student.dropoffLabel != null)
                          'Destino: ${student.dropoffLabel}',
                      ].join(' · '),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.slate),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      FilledButton.tonal(
                        onPressed:
                            widget.submitting || !widget.routeActive ? null : widget.onBoard,
                        child: const Text('Embarcou'),
                      ),
                      OutlinedButton(
                        onPressed:
                            widget.submitting || !widget.routeActive
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
                          side: const BorderSide(color: AppColors.danger, width: 1),
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
              const Icon(Icons.campaign_rounded, size: 20, color: Color(0xFFF57C00)),
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
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            child: const Text('Enviar alerta'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final routeId = widget.tracking.routeId;
    final session = ref.read(appSessionControllerProvider).session;
    if (routeId == null || routeId <= 0 || session == null) return;

    setState(() => _sending = true);
    try {
      final result = await ref.read(driverPortalRepositoryProvider).alertAllParents(
            session.authorizationHeader,
            routeId,
            type: type,
          );
      if (!mounted) return;
      final count = result['notified_count'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alerta enviado para $count responsável(is).')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
    final boardingsCount = (route['boardings_count'] ?? 0).toString();
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
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (isThisRoute) const _StatusPill(label: 'Ativa', active: true),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Status: $status · Embarques: $boardingsCount',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.slate),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.tonal(
                onPressed:
                    routeId <= 0 ? null : () => _handleAction(context, ref, true),
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

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    bool start,
  ) async {
    try {
      final routeId = (route['id'] as num?)?.toInt() ?? 0;
      if (routeId <= 0) throw ApiException(message: 'Rota invalida.');
      final session = ref.read(appSessionControllerProvider).session;
      if (session == null) throw ApiException(message: 'Sessao expirada.');
      final auth = session.authorizationHeader;
      final repo = ref.read(driverPortalRepositoryProvider);
      final ctrl = ref.read(driverTrackingControllerProvider.notifier);

      if (start) {
        final response = await repo.startRoute(auth, routeId, vanId: session.user.id);
        if (!context.mounted) return;
        await _startTrackingFromResponse(context, ref, response,
            fallbackRouteId: routeId);
        if (!context.mounted) return;
      } else {
        await repo.finishRoute(auth, routeId);
        await ctrl.stopRouteTracking(silent: true);
      }
      ref.invalidate(driverRoutesProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(start ? 'Rota iniciada.' : 'Rota finalizada.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

// ─────────────────────────────────────────────
// Adhoc Route Planner
// ─────────────────────────────────────────────

Future<void> _openAdhocPlanner(BuildContext context, WidgetRef ref) async {
  final session = ref.read(appSessionControllerProvider).session;
  if (session == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sessao expirada. Faca login novamente.')),
    );
    return;
  }

  final repo = ref.read(driverPortalRepositoryProvider);
  final optionsFuture = repo.routePlanningOptions(session.authorizationHeader);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => FutureBuilder<Map<String, dynamic>>(
      future: optionsFuture,
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
            child: Text(snapshot.error.toString(), textAlign: TextAlign.center),
          );
        }
        return _AdhocPlannerContent(
          data: snapshot.data ?? const {},
          onStart: (payload) async {
            double? originLat, originLng;
            try {
              final pos = await Geolocator.getCurrentPosition();
              originLat = pos.latitude;
              originLng = pos.longitude;
            } catch (_) {}

            final response = await repo.startAdhocRoute(
              session.authorizationHeader,
              shiftId: null,
              tripMode: payload.tripModeId,
              operationId: payload.operationId,
              routeName: payload.routeName,
              originLat: originLat,
              originLng: originLng,
              selections: payload.selections,
            );
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

class _PlannerPayload {
  const _PlannerPayload({
    this.operationId,
    required this.tripModeId,
    this.routeName,
    required this.selections,
  });
  final String? operationId;
  final String tripModeId;
  final String? routeName;
  final List<Map<String, int>> selections;
}

class _AdhocPlannerContent extends StatefulWidget {
  const _AdhocPlannerContent({required this.data, required this.onStart});
  final Map<String, dynamic> data;
  final Future<void> Function(_PlannerPayload) onStart;

  @override
  State<_AdhocPlannerContent> createState() => _AdhocPlannerContentState();
}

class _AdhocPlannerContentState extends State<_AdhocPlannerContent> {
  final _nameCtrl = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _opId;
  final Map<int, bool> _selected = {};
  final Map<int, int> _addressOf = {};

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ops = _listOf(widget.data['operation_windows']);
    final tripModes = _listOf(widget.data['trip_modes']);
    final students = _listOf(widget.data['students']);

    if (_opId == null || !ops.any((e) => _idStr(e) == _opId)) {
      _opId = ops.isNotEmpty ? _idStr(ops.first) : null;
    }

    final filtered = students
        .where((s) {
          if (_opId == null) return true;
          final ids = ((s['operation_window_ids'] as List?) ?? [])
              .map((e) => e.toString())
              .toSet();
          return ids.contains(_opId);
        })
        .toList(growable: false)
      ..sort((a, b) {
        final c = (a['shift_name'] ?? '').toString();
        final d = (b['shift_name'] ?? '').toString();
        if (c != d) return c.compareTo(d);
        return (a['child_name'] ?? '')
            .toString()
            .compareTo((b['child_name'] ?? '').toString());
      });

    for (final s in filtered) {
      final cid = _numId(s['child_id']);
      final addrs = _listOf(s['addresses']);
      if (cid > 0 && !_selected.containsKey(cid)) _selected[cid] = true;
      if (cid > 0 && !_addressOf.containsKey(cid) && addrs.isNotEmpty) {
        final def = addrs.firstWhere(
          (e) => e['is_default'] == true,
          orElse: () => addrs.first,
        );
        final aid = _numId(def['id']);
        if (aid > 0) _addressOf[cid] = aid;
      }
    }

    final tripModeId = _resolveTripMode(_opId, tripModes);

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
            'Planejar rota',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Escolha o momento, confirme os alunos e endereco.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.slate),
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String?>(
            initialValue: _opId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Momento da rota'),
            items: ops
                .map(
                  (op) => DropdownMenuItem<String?>(
                    value: _idStr(op),
                    child: Text(
                      (op['label'] ?? '').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: _busy ? null : (v) => setState(() => _opId = v),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _nameCtrl,
            enabled: !_busy,
            decoration: const InputDecoration(labelText: 'Nome da rota (opcional)'),
          ),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: filtered.isEmpty
                ? const Center(child: Text('Nenhum aluno para este momento.'))
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) => _buildStudentItem(filtered[i]),
                  ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: TextStyle(color: AppColors.danger, fontSize: 13)),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _busy ? null : () => _submit(filtered, tripModeId),
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

  Widget _buildStudentItem(Map<String, dynamic> s) {
    final cid = _numId(s['child_id']);
    final addrs = _listOf(s['addresses']);
    final sel = _selected[cid] ?? false;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckboxListTile(
            value: sel,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              (s['child_name'] ?? 'Aluno #$cid').toString(),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                if ((s['parent_name'] ?? '').toString().isNotEmpty)
                  'Resp.: ${s['parent_name']}',
                if ((s['school_name'] ?? '').toString().isNotEmpty)
                  'Escola: ${s['school_name']}',
              ].join(' · '),
            ),
            onChanged: _busy
                ? null
                : (v) => setState(() => _selected[cid] = v ?? false),
          ),
          if (sel && addrs.isNotEmpty)
            DropdownButtonFormField<int>(
              initialValue: _addressOf[cid],
              isExpanded: true,
              decoration:
                  const InputDecoration(labelText: 'Endereco de embarque'),
              items: addrs
                  .map((a) {
                    final id = _numId(a['id']);
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(
                        (a['label'] ?? 'Endereco #$id').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  })
                  .toList(growable: false),
              onChanged: _busy
                  ? null
                  : (v) {
                      if (v != null) setState(() => _addressOf[cid] = v);
                    },
            ),
          if (sel && addrs.isEmpty)
            Text(
              'Aluno sem endereco cadastrado.',
              style: TextStyle(color: AppColors.danger, fontSize: 13),
            ),
        ],
      ),
    );
  }

  Future<void> _submit(
    List<Map<String, dynamic>> filtered,
    String? tripModeId,
  ) async {
    if (tripModeId == null || tripModeId.isEmpty) {
      setState(
        () => _error = 'Nao foi possivel determinar a operacao tecnica da rota.',
      );
      return;
    }
    final selections = <Map<String, int>>[];
    for (final s in filtered) {
      final cid = _numId(s['child_id']);
      final clid = _numId(s['client_id']);
      if (!(_selected[cid] ?? false)) continue;
      final aid = _addressOf[cid];
      if (cid <= 0 || clid <= 0 || aid == null || aid <= 0) {
        setState(() => _error = 'Selecione o endereco dos alunos marcados.');
        return;
      }
      selections.add({'client_id': clid, 'child_id': cid, 'address_id': aid});
    }
    if (selections.isEmpty) {
      setState(() => _error = 'Selecione pelo menos um aluno.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onStart(
        _PlannerPayload(
          operationId: _opId,
          tripModeId: tripModeId,
          routeName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
          selections: selections,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rota planejada e iniciada.')),
      );
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
  Map<String, dynamic> response, {
  int? fallbackRouteId,
}) async {
  final session = ref.read(appSessionControllerProvider).session;
  if (session == null) throw ApiException(message: 'Sessao expirada.');

  final routeMap =
      (response['route'] as Map?)?.cast<String, dynamic>() ?? const {};
  final manifest =
      (response['route_manifest'] as Map?)?.cast<String, dynamic>() ?? const {};
  final routeId =
      (routeMap['id'] as num?)?.toInt() ?? fallbackRouteId ?? 0;
  final manifestId = manifest['id']?.toString();
  final vanId = (manifest['van_id'] as num?)?.toInt();

  if (routeId <= 0 || manifestId == null || manifestId.isEmpty) {
    throw ApiException(
      message: 'Backend nao retornou dados suficientes para iniciar.',
    );
  }
  if (vanId == null || vanId <= 0) {
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

  final preview =
      (response['route_preview'] as Map?)?.cast<String, dynamic>() ?? const {};
  final meta =
      (manifest['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
  final stops = ((meta['optimized_stops'] as List?) ?? [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);

  ctrl.primeRoutePreview(
    remainingStops: stops,
    geometry: preview['geometry'] is Map
        ? Map<String, dynamic>.from(preview['geometry'] as Map)
        : null,
    distanceMeters: (preview['distance_meters'] as num?)?.toDouble(),
    durationSeconds: (preview['duration_seconds'] as num?)?.toInt(),
  );
}

List<_StudentCard> _studentRouteCards(DriverTrackingState tracking) {
  final planned = tracking.routePlannedStops;
  if (planned.isEmpty) return const [];

  final nextKey = tracking.routeRemainingStops.isNotEmpty
      ? _keyOf(tracking.routeRemainingStops.first)
      : null;

  final grouped = <String, List<DriverTrackingStopPoint>>{};
  for (final stop in planned) {
    if ((stop.clientId ?? 0) <= 0) continue;
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
    final anyDelivered =
        stops.any((s) => s.status.toLowerCase() == 'delivered');
    final anyPicked =
        stops.any((s) => s.status.toLowerCase() == 'picked_up');
    final status = anyDelivered
        ? _StopStatus.droppedOff
        : anyPicked
            ? _StopStatus.boarded
            : (entry.key == nextKey
                ? _StopStatus.onTheWay
                : _StopStatus.pending);
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
  if ((s.clientId ?? 0) > 0) return 'c:${s.clientId}';
  if ((s.childId ?? 0) > 0) return 'ch:${s.childId}';
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

String? _resolveTripMode(String? opId, List<Map<String, dynamic>> modes) {
  if (opId == null || opId.isEmpty) return null;
  final preferred = switch (opId) {
    'morning_entry' => 'morning_home_to_school',
    'morning_afternoon_transition' => 'afternoon_school_to_home_lunch',
    'afternoon_night_transition' => 'afternoon_school_to_home_end',
    'night_exit' => 'night_school_to_home',
    _ => 'adhoc',
  };
  final ids = modes.map((m) => (m['id'] ?? '').toString()).toList();
  if (ids.contains(preferred)) return preferred;
  if (ids.isNotEmpty) return ids.first;
  return preferred;
}

List<Map<String, dynamic>> _listOf(dynamic v) =>
    ((v as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);

String _idStr(Map<String, dynamic> m) => (m['id'] ?? '').toString();

int _numId(dynamic v) => (v as num?)?.toInt() ?? 0;
