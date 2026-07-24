import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/dashboard/dashboard_status_card.dart';

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
    final schoolName = _extractSchoolName(activeRoute);
    final departureTime = _extractDepartureTime(activeRoute);

    return DashboardStatusCard(
      active: hasActiveRoute,
      title: hasActiveRoute ? 'Rota em andamento' : 'Nenhuma rota ativa',
      subtitle: hasActiveRoute
          ? [
              schoolName,
              if (departureTime != null) 'Saida: $departureTime',
            ].nonNulls.join(' \u2022 ')
          : 'Nenhuma rota ativa no momento.',
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

  String? _extractSchoolName(Map<String, dynamic>? route) {
    if (route == null) return null;
    final candidates = [
      route['schoolName'],
      route['school'],
      route['name'],
      (route['school'] as Map<String, dynamic>?)?['name'],
    ];
    for (final value in candidates) {
      final text = value?.toString();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  String? _extractDepartureTime(Map<String, dynamic>? route) {
    if (route == null) return null;
    final candidates = [
      route['departureTime'],
      route['startTime'],
      route['time'],
      route['scheduledTime'],
    ];
    for (final value in candidates) {
      final text = value?.toString();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }
}
