import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/dashboard/dashboard_status_card.dart';
import '../../../../core/utils/date_formatters.dart';

/// Subtítulo do card de rota ativa, derivado das chaves que o backend
/// realmente envia em `GET /parent/routes` (APP-09):
/// `driver.name`, `van.plate` e `activeManifest.startedAt`
/// (fallback: `startedAt` da própria rota).
///
/// Extraído como função pura para ser testável isoladamente — antes o card
/// lia chaves inexistentes (`schoolName`, `departureTime`) e o subtítulo
/// saía sempre vazio.
String routeStatusSubtitle(Map<String, dynamic>? activeRoute) {
  if (activeRoute == null || activeRoute.isEmpty) {
    return 'Nenhuma rota ativa no momento.';
  }

  final driver = activeRoute['driver'];
  final driverName = driver is Map ? driver['name']?.toString().trim() : null;

  final van = activeRoute['van'];
  final vanPlate = van is Map ? van['plate']?.toString().trim() : null;

  final manifest = activeRoute['activeManifest'];
  final startedAtRaw = manifest is Map && manifest['startedAt'] != null
      ? manifest['startedAt']
      : activeRoute['startedAt'];
  final startedAt = startedAtRaw != null
      ? DateTime.tryParse(startedAtRaw.toString())
      : null;
  final startedLabel = formatTime(startedAt);

  final parts = <String>[
    if (driverName != null && driverName.isNotEmpty) driverName,
    if (vanPlate != null && vanPlate.isNotEmpty) vanPlate.toUpperCase(),
    if (startedLabel.isNotEmpty) 'Saída: $startedLabel',
  ];

  return parts.isEmpty
      ? 'Toque em "Ver no mapa" para acompanhar.'
      : parts.join(' \u2022 ');
}

/// Card de status da rota ativa do responsavel.
class ParentRouteStatusCard extends StatelessWidget {
  const ParentRouteStatusCard({
    super.key,
    this.activeRoute,
    this.onViewMap,
  });

  final Map<String, dynamic>? activeRoute;
  final VoidCallback? onViewMap;

  @override
  Widget build(BuildContext context) {
    final hasActiveRoute = activeRoute != null && activeRoute!.isNotEmpty;

    return DashboardStatusCard(
      active: hasActiveRoute,
      title: hasActiveRoute ? 'Rota em andamento' : 'Nenhuma rota ativa',
      subtitle: routeStatusSubtitle(activeRoute),
      activeIcon: Icons.directions_bus_filled_rounded,
      inactiveIcon: Icons.info_outline_rounded,
      child: hasActiveRoute && onViewMap != null
          ? SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onViewMap,
                icon: const Icon(Icons.map_rounded),
                label: const Text('Ver no mapa'),
              ),
            )
          : null,
    );
  }
}
