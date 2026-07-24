import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/app_error_reporter.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../../domain/models/child.dart';
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
        ref.invalidate(parentRoutesProvider);
        ref.invalidate(parentChildrenProvider);
      }
    });
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(parentRoutesProvider);
    final childrenAsync = ref.watch(parentChildrenProvider);

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
            return NoActiveRoutesState(hasChildren: children.isNotEmpty);
          }

          if (_selectedRouteIndex >= activeRoutes.length) {
            _selectedRouteIndex = 0;
          }

          final route = activeRoutes[_selectedRouteIndex];
          final manifest = route['activeManifest'] as Map<String, dynamic>?;
          final manifestChildIds = _extractChildIdsFromManifest(manifest);

          final myDependents = children.where((c) {
            return manifestChildIds.contains(c.id);
          }).toList();

          final latestLocation =
              route['latestLocation'] as Map<String, dynamic>?;
          final driverLat = (latestLocation?['latitude'] as num?)?.toDouble();
          final driverLng = (latestLocation?['longitude'] as num?)?.toDouble();
          final driverPos = (driverLat != null && driverLng != null)
              ? LatLng(driverLat, driverLng)
              : null;
          final latestLocationAtRaw = route['latestLocationAt'];
          final lastPositionAt = latestLocationAtRaw == null
              ? null
              : DateTime.tryParse(latestLocationAtRaw.toString());

          return Stack(
            children: [
              Positioned.fill(child: DriverLocationMap(driverPos: driverPos)),
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
                        routes: activeRoutes,
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
