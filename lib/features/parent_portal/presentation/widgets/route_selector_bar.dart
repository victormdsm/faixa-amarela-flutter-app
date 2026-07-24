import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Barra de seleção de qual rota ativa o responsável deseja acompanhar.
class RouteSelectorBar extends StatelessWidget {
  const RouteSelectorBar({
    super.key,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSubtle,
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
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(routes.length, (i) {
                final r = routes[i];
                final driverName =
                    ((r['driver'] as Map?)?['name'] ?? 'Motorista').toString();
                final selected = i == selectedIndex;
                return Padding(
                  padding: EdgeInsets.only(
                    right: i < routes.length - 1 ? AppSpacing.sm : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => onSelect(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm - 1,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.yellow
                            : AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppRadius.full),
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
