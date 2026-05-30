import 'package:flutter/material.dart';

class FaixaNavItem {
  const FaixaNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;
}

class FaixaBottomNav extends StatelessWidget {
  const FaixaBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<FaixaNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: items
          .map(
            (item) => NavigationDestination(
              icon: item.badgeCount > 0
                  ? Badge(
                      label: Text('${item.badgeCount}'),
                      child: Icon(item.icon),
                    )
                  : Icon(item.icon),
              selectedIcon: item.badgeCount > 0
                  ? Badge(
                      label: Text('${item.badgeCount}'),
                      child: Icon(item.activeIcon),
                    )
                  : Icon(item.activeIcon),
              label: item.label,
            ),
          )
          .toList(growable: false),
    );
  }
}
