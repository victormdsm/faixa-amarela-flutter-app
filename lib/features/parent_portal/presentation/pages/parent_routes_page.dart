import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../providers/parent_portal_providers.dart';

// ─── Page ────────────────────────────────────────────────────────────────────

class ParentRoutesPage extends ConsumerStatefulWidget {
  const ParentRoutesPage({super.key});

  @override
  ConsumerState<ParentRoutesPage> createState() => _ParentRoutesPageState();
}

class _ParentRoutesPageState extends ConsumerState<ParentRoutesPage> {
  Timer? _refreshTimer;
  int _selectedRouteIndex = 0;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        ref.invalidate(parentRoutesProvider);
        ref.invalidate(parentChildrenProvider);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(parentRoutesProvider);
    final childrenAsync = ref.watch(parentChildrenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acompanhar Percurso'),
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
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(parentRoutesProvider);
            ref.invalidate(parentChildrenProvider);
          },
        ),
        data: (routesPage) {
          final children = childrenAsync.maybeWhen(
            data: (page) => page.items,
            orElse: () => <Map<String, dynamic>>[],
          );

          // Somente rotas com manifesto ativo (motorista em movimento)
          final activeRoutes = routesPage.items.where((r) {
            final manifest = r['active_manifest'] as Map?;
            if (manifest == null) return false;
            final status =
                manifest['status']?.toString().toLowerCase() ?? '';
            return status != 'finished' && status != 'cancelled';
          }).toList();

          if (activeRoutes.isEmpty) {
            return _NoActiveRoutesState(hasChildren: children.isNotEmpty);
          }

          if (_selectedRouteIndex >= activeRoutes.length) {
            _selectedRouteIndex = 0;
          }

          final route = activeRoutes[_selectedRouteIndex];
          final routeDriverId =
              (route['driver'] as Map?)?['id'] as num?;

          // Dependentes do pai nesta rota
          final myDependents = children.where((c) {
            final driverId = (c['driver_id'] as num?) ??
                ((c['client'] as Map?)?['driver_id'] as num?);
            return routeDriverId != null && driverId == routeDriverId;
          }).toList();

          final latestLocation =
              (route['latest_location'] as Map?)?.cast<String, dynamic>();
          final driverLat =
              (latestLocation?['latitude'] as num?)?.toDouble();
          final driverLng =
              (latestLocation?['longitude'] as num?)?.toDouble();
          final driverPos =
              (driverLat != null && driverLng != null)
                  ? LatLng(driverLat, driverLng)
                  : null;

          return Stack(
            children: [
              // ── Mapa full-screen ──
              Positioned.fill(
                child: _FullScreenDriverMap(driverPos: driverPos),
              ),

              // ── Seletor de rota (só quando múltiplas rotas ativas) ──
              if (activeRoutes.length > 1)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: _RouteSelectorBar(
                        routes: activeRoutes,
                        selectedIndex: _selectedRouteIndex,
                        onSelect: (i) =>
                            setState(() => _selectedRouteIndex = i),
                      ),
                    ),
                  ),
                ),

              // ── Overlay inferior: live badge + dependentes ──
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: _LiveBottomOverlay(
                    dependents: myDependents,
                    driverPos: driverPos,
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

// ─── Full-screen Driver Map ───────────────────────────────────────────────────

class _FullScreenDriverMap extends StatelessWidget {
  const _FullScreenDriverMap({required this.driverPos});
  final LatLng? driverPos;

  @override
  Widget build(BuildContext context) {
    final center = driverPos ?? const LatLng(-25.5401, -54.5854);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: driverPos != null ? 15.0 : 13.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.drag |
              InteractiveFlag.pinchZoom |
              InteractiveFlag.doubleTapZoom,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'br.com.faixaamarela.app',
        ),
        if (driverPos != null)
          MarkerLayer(
            markers: [
              Marker(
                point: driverPos!,
                width: 52,
                height: 52,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.ink, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: AppColors.ink,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ─── Route Selector Bar ───────────────────────────────────────────────────────

class _RouteSelectorBar extends StatelessWidget {
  const _RouteSelectorBar({
    required this.routes,
    required this.selectedIndex,
    required this.onSelect,
  });
  final List<Map<String, dynamic>> routes;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Escolha qual rota acompanhar',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.slate,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(routes.length, (i) {
                final r = routes[i];
                final driverName =
                    ((r['driver'] as Map?)?['name'] ?? 'Motorista')
                        .toString();
                final selected = i == selectedIndex;
                return Padding(
                  padding: EdgeInsets.only(
                      right: i < routes.length - 1 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => onSelect(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.yellow
                            : const Color(0xFFF5F0E8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.ink.withValues(alpha: 0.2)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.directions_bus_rounded,
                            size: 14,
                            color: AppColors.ink,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            driverName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Live Overlay ──────────────────────────────────────────────────────

class _LiveBottomOverlay extends StatelessWidget {
  const _LiveBottomOverlay({
    required this.dependents,
    required this.driverPos,
  });
  final List<Map<String, dynamic>> dependents;
  final LatLng? driverPos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulsingDot(color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      'AO VIVO',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (driverPos == null)
                Text(
                  'Aguardando GPS do motorista…',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.slate,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          if (dependents.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Meus dependentes nesta rota',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.slate,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: dependents.map((dep) {
                final name =
                    (dep['name'] ?? dep['child']?['name'] ?? '')
                        .toString();
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          AppColors.yellow.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.child_care_rounded,
                        size: 13,
                        color: Color(0xFFC9870A),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        name.isEmpty ? 'Dependente' : name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFC9870A),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _NoActiveRoutesState extends StatelessWidget {
  const _NoActiveRoutesState({required this.hasChildren});
  final bool hasChildren;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.yellow.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bus_outlined,
                size: 38,
                color: AppColors.yellow,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasChildren
                  ? 'Nenhum percurso ativo agora'
                  : 'Nenhum dependente cadastrado',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasChildren
                  ? 'Quando o motorista do seu dependente\niniciar uma rota, o mapa aparecerá aqui\nem tempo real.'
                  : 'Cadastre um dependente na aba\n"Dependentes" para acompanhar\nos percursos.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.slate,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pulsing Dot ─────────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _anim.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
