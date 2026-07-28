import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

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

/// Bottom navigation padronizada do aplicativo.
///
/// - Altura 64 + safe area ([SafeArea] `top: false` — em aparelhos com
///   gesture bar/MIUI a barra do sistema não cobre os destinos).
/// - Fundo branco ([AppColors.surface]).
/// - Indicador de seleção amarelo com opacidade 0.12.
/// - Ícones outlined inativo / filled ativo (definidos em [FaixaNavItem]).
/// - Labels sempre visíveis.
/// - Cor selecionada [AppColors.yellow]; inativo [AppColors.muted].
/// - Fonte Inter 11 semibold selecionado / medium inativo.
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
    const inter = TextStyle(fontFamily: 'Inter');

    return SafeArea(
      top: false,
      child: NavigationBarTheme(
        data: NavigationBarTheme.of(context).copyWith(
          backgroundColor: AppColors.surface,
          elevation: 0,
          height: 64,
          indicatorColor: AppColors.yellow.withValues(alpha: 0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.yellow, size: 24);
            }
            return const IconThemeData(color: AppColors.muted, size: 24);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return inter.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.yellow,
              );
            }
            return inter.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            );
          }),
        ),
        child: NavigationBar(
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
        ),
      ),
    );
  }
}
