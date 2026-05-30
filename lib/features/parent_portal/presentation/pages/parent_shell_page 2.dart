import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/widgets/faixa_bottom_nav.dart';

class ParentShellPage extends StatelessWidget {
  const ParentShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: FaixaBottomNav(
        items: const [
          FaixaNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Inicio',
          ),
          FaixaNavItem(
            icon: Icons.child_care_outlined,
            activeIcon: Icons.child_care_rounded,
            label: 'Dependentes',
          ),
          FaixaNavItem(
            icon: Icons.route_outlined,
            activeIcon: Icons.route_rounded,
            label: 'Rotas',
          ),
          FaixaNavItem(
            icon: Icons.hail_outlined,
            activeIcon: Icons.hail_rounded,
            label: 'Embarques',
          ),
          FaixaNavItem(
            icon: Icons.notifications_none_rounded,
            activeIcon: Icons.notifications_rounded,
            label: 'Avisos',
          ),
        ],
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
