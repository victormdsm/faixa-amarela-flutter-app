import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/app_error_reporter.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../../domain/models/child.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../providers/parent_portal_providers.dart';
import '../widgets/driver_location_map.dart';
import '../widgets/live_tracking_overlay.dart';
import '../widgets/no_active_routes_state.dart';
import '../widgets/route_selector_bar.dart';

class ParentRoutesPage extends ConsumerStatefulWidget {
  const ParentRoutesPage({super.key});

  @override
  ConsumerState<ParentRoutesPage> createState() => _ParentRoutesPageState();
}

class _ParentRoutesPageState extends ConsumerState<ParentRoutesPage>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  int _selectedRouteIndex = 0;
  int _liveFallbackTicks = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startRefreshTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startRefreshTimer();
    } else {
      _stopRefreshTimer();
    }
  }

  void _startRefreshTimer() {
    _stopRefreshTimer();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        // Com o socket ao vivo o marcador já atualiza em tempo real — mas
        // eventos de status podem se perder em janelas de reconexão, então o
        // polling não desliga: vira um safety net espaçado (~60s).
        final realtime = ref.read(parentRealtimeControllerProvider);
        if (realtime.isLive) {
          _liveFallbackTicks++;
          if (_liveFallbackTicks < 4) return;
        }
        _liveFallbackTicks = 0;
        ref.invalidate(parentRoutesProvider);
        ref.invalidate(parentChildrenProvider);
      }
    });
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _liveFallbackTicks = 0;
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(parentRoutesProvider);
    final childrenAsync = ref.watch(parentChildrenProvider);
    // Sempre observado enquanto a tela está aberta: ao sair daqui o provider
    // (autoDispose) encerra o socket sozinho.
    final realtime = ref.watch(parentRealtimeControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      appBar: FaixaAppBar.screen(
        title: 'Acompanhar Percurso',
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () {
              ref.invalidate(parentRoutesProvider);
              ref.invalidate(parentChildrenProvider);
            },
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
        ],
      ),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => FaixaErrorState(
          message: AppErrorReporter.messageFor(error),
          onRetry: () {
            ref.invalidate(parentRoutesProvider);
            ref.invalidate(parentChildrenProvider);
          },
        ),
        data: (routesPage) {
          final children = childrenAsync.maybeWhen(
            data: (page) => page.items,
            orElse: () => <Child>[],
          );

          final activeRoutes = routesPage.items.where((r) {
            final manifest = r['activeManifest'] as Map<String, dynamic>?;
            if (manifest == null) return false;
            final status = manifest['status']?.toString().toLowerCase() ?? '';
            return status != 'finished' && status != 'cancelled';
          }).toList();

          if (activeRoutes.isEmpty) {
            // Rota finalizada: encerra a assinatura do socket, se houver.
            if (realtime.routeId != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                ref.read(parentRealtimeControllerProvider.notifier).unwatch();
              });
            }
            return NoActiveRoutesState(hasChildren: children.isNotEmpty);
          }

          if (_selectedRouteIndex >= activeRoutes.length) {
            _selectedRouteIndex = 0;
          }

          final route = activeRoutes[_selectedRouteIndex];
          final routeId = (route['id'] as num?)?.toInt();
          // Assina a rota selecionada no socket (uma vez por troca de rota).
          if (routeId != null && routeId > 0 && routeId != realtime.routeId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final token = ref
                  .read(appSessionControllerProvider)
                  .session
                  ?.accessToken;
              if (token == null || token.isEmpty) return;
              ref
                  .read(parentRealtimeControllerProvider.notifier)
                  .watchRoute(routeId: routeId, token: token);
            });
          }

          final manifest = route['activeManifest'] as Map<String, dynamic>?;
          final manifestChildIds = _extractChildIdsFromManifest(manifest);

          final myDependents = children.where((c) {
            return manifestChildIds.contains(c.id);
          }).toList();

          final latestLocation =
              route['latestLocation'] as Map<String, dynamic>?;
          final driverLat = (latestLocation?['latitude'] as num?)?.toDouble();
          final driverLng = (latestLocation?['longitude'] as num?)?.toDouble();
          final httpDriverPos = (driverLat != null && driverLng != null)
              ? LatLng(driverLat, driverLng)
              : null;
          final latestLocationAtRaw = route['latestLocationAt'];
          final httpLastPositionAt = latestLocationAtRaw == null
              ? null
              : DateTime.tryParse(latestLocationAtRaw.toString());

          // Socket tem prioridade; posição/timestamp do HTTP são o fallback.
          final driverPos = realtime.position ?? httpDriverPos;
          final lastPositionAt = realtime.updatedAt ?? httpLastPositionAt;

          return Stack(
            children: [
              Positioned.fill(
                child: DriverLocationMap(
                  driverPos: driverPos,
                  schoolPoints: _extractSchoolStopPointsFromManifest(manifest),
                ),
              ),
              if (activeRoutes.length > 1)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        0,
                      ),
                      child: RouteSelectorBar(
                        entries: _buildSelectorEntries(
                          activeRoutes,
                          children,
                        ),
                        selectedIndex: _selectedRouteIndex,
                        onSelect: (i) =>
                            setState(() => _selectedRouteIndex = i),
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: LiveTrackingOverlay(
                    dependents: myDependents,
                    driverPos: driverPos,
                    lastPositionAt: lastPositionAt,
                    isLive: realtime.isLive,
                    connectionIssue: realtime.connectionIssue,
                    onRetry: () => ref
                        .read(parentRealtimeControllerProvider.notifier)
                        .retry(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Monta os rótulos do seletor: cada rota ativa é identificada pelos
/// dependentes do responsável que estão naquele manifesto (e pelo motorista
/// como informação secundária).
List<RouteSelectorEntry> _buildSelectorEntries(
  List<Map<String, dynamic>> routes,
  List<Child> children,
) {
  return routes.map((route) {
    final manifest = route['activeManifest'] as Map<String, dynamic>?;
    final childIds = _extractChildIdsFromManifest(manifest);
    return RouteSelectorEntry(
      driverName: ((route['driver'] as Map?)?['name'] ?? 'Motorista')
          .toString(),
      dependentNames: children
          .where((c) => childIds.contains(c.id))
          .map((c) => c.name)
          .toList(growable: false),
    );
  }).toList(growable: false);
}

Set<int> _extractChildIdsFromManifest(Map<String, dynamic>? manifest) {
  final ids = <int>{};
  if (manifest == null) return ids;

  final document = manifest['document'] as Map<String, dynamic>?;
  final children = document?['children'];
  if (children is List) {
    for (final child in children) {
      if (child is Map<String, dynamic>) {
        final id = (child['childId'] as num?)?.toInt();
        if (id != null) ids.add(id);
      }
    }
  }

  final stops = manifest['stops'];
  if (stops is List) {
    for (final stop in stops) {
      if (stop is Map<String, dynamic>) {
        final id = (stop['childId'] as num?)?.toInt();
        if (id != null) ids.add(id);
      }
    }
  }

  return ids;
}

/// Pontos das escolas da rota (stops type "school" com coordenadas) para o
/// mapa do responsável exibir a âncora da viagem durante o percurso.
List<LatLng> _extractSchoolStopPointsFromManifest(
  Map<String, dynamic>? manifest,
) {
  if (manifest == null) return const [];
  final stops = manifest['stops'];
  if (stops is! List) return const [];

  final points = <LatLng>[];
  for (final stop in stops) {
    if (stop is! Map) continue;
    final map = Map<String, dynamic>.from(stop);
    if (map['type']?.toString().toLowerCase() != 'school') continue;
    final lat = (map['latitude'] as num?)?.toDouble();
    final lng = (map['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) continue;
    points.add(LatLng(lat, lng));
  }
  return points;
}
