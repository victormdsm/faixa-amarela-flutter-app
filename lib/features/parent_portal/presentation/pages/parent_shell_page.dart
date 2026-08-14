import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/widgets/faixa_bottom_nav.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';

class ParentShellPage extends ConsumerWidget {
  const ParentShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: FaixaBottomNav(
        items: [
          const FaixaNavItem(
            icon: Icons.home_rounded,
            activeIcon: Icons.home_rounded,
            label: 'Início',
          ),
          const FaixaNavItem(
            icon: Icons.child_care_rounded,
            activeIcon: Icons.child_care_rounded,
            label: 'Dependentes',
          ),
          const FaixaNavItem(
            icon: Icons.route_rounded,
            activeIcon: Icons.route_rounded,
            label: 'Rotas',
          ),
          const FaixaNavItem(
            icon: Icons.fact_check_rounded,
            activeIcon: Icons.fact_check_rounded,
            label: 'Embarques',
          ),
          FaixaNavItem(
            icon: Icons.notifications_none_rounded,
            activeIcon: Icons.notifications_rounded,
            label: 'Avisos',
            badgeCount: unreadCount,
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
