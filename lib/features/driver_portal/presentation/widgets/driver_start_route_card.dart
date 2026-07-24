import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/dashboard/dashboard_status_card.dart';

/// Card exibido quando nao ha rota ativa, permitindo iniciar uma nova rota.
class DriverStartRouteCard extends StatelessWidget {
  const DriverStartRouteCard({
    super.key,
    this.onStart,
    this.isLoading = false,
  });

  final VoidCallback? onStart;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DashboardStatusCard(
      active: false,
      title: 'Iniciar nova rota',
      subtitle:
          'Nenhuma rota ativa no momento. Inicie uma nova rota quando estiver pronto.',
      activeIcon: Icons.route_outlined,
      inactiveIcon: Icons.route_outlined,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: isLoading ? null : onStart,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow_rounded),
          label: const Text('Iniciar rota'),
        ),
      ),
    );
  }
}
