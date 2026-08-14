import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Uma rota ativa disponível para acompanhamento.
class RouteSelectorEntry {
  const RouteSelectorEntry({
    required this.driverName,
    required this.dependentNames,
  });

  final String driverName;

  /// Dependentes do responsável que estão no manifesto desta rota. É o que
  /// diferencia duas rotas simultâneas para quem tem mais de um dependente.
  final List<String> dependentNames;

  /// Rótulo curto do chip: os dependentes quando conhecidos, senão o
  /// motorista.
  String get label {
    if (dependentNames.isEmpty) return driverName;
    return dependentNames.map(_firstName).join(', ');
  }

  static String _firstName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed.split(RegExp(r'\s+')).first;
  }
}

/// Barra de seleção de qual rota ativa o responsável deseja acompanhar.
///
/// Exibida apenas quando o backend (`GET /parent/routes`) devolve mais de uma
/// rota ativa — o endpoint já retorna todas as rotas em andamento dos
/// motoristas vinculados aos dependentes, uma por motorista.
class RouteSelectorBar extends StatelessWidget {
  const RouteSelectorBar({
    super.key,
    required this.entries,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<RouteSelectorEntry> entries;
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
            '${entries.length} rotas ativas — escolha qual acompanhar',
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
              children: List.generate(entries.length, (i) {
                final entry = entries[i];
                final selected = i == selectedIndex;
                return Padding(
                  padding: EdgeInsets.only(
                    right: i < entries.length - 1 ? AppSpacing.sm : 0,
                  ),
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label:
                        '${entry.label} — motorista ${entry.driverName}',
                    child: GestureDetector(
                      onTap: () => onSelect(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        constraints: const BoxConstraints(minHeight: 44),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  entry.label,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  entry.driverName,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: AppColors.slate,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
