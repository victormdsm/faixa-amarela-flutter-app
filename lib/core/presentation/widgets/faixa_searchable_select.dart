import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// Campo que abre um bottom sheet com busca e seleção múltipla.
///
/// Útil para substituir seleções extensas de escolas, bairros, turnos etc.
///
/// ```dart
/// FaixaSearchableSelect<CatalogOption>(
///   label: 'Escolas atendidas',
///   count: selectedSchoolIds.length,
///   items: schools,
///   selectedIds: selectedSchoolIds,
///   itemToId: (item) => item.id,
///   itemToName: (item) => item.name,
///   title: 'Escolas atendidas',
///   searchHint: 'Buscar escola',
///   onConfirm: (ids) => setState(() { ... }),
/// )
/// ```
class FaixaSearchableSelect<T> extends StatelessWidget {
  const FaixaSearchableSelect({
    super.key,
    required this.label,
    required this.count,
    required this.items,
    required this.selectedIds,
    required this.itemToId,
    required this.itemToName,
    required this.title,
    required this.searchHint,
    required this.onConfirm,
    this.onClear,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final int count;
  final List<T> items;
  final Set<int> selectedIds;
  final int Function(T) itemToId;
  final String Function(T) itemToName;
  final String title;
  final String searchHint;
  final ValueChanged<Set<int>> onConfirm;
  final VoidCallback? onClear;
  final IconData? icon;
  final bool enabled;

  Future<void> _openSheet(BuildContext context) async {
    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => _SearchableSelectSheet<T>(
        title: title,
        searchHint: searchHint,
        items: items,
        selectedIds: selectedIds,
        itemToId: itemToId,
        itemToName: itemToName,
        onClear: onClear,
      ),
    );

    if (result != null) {
      onConfirm(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCount = count > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => _openSheet(context) : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: hasCount ? AppColors.yellow : AppColors.border,
            ),
            color: hasCount
                ? AppColors.yellow.withValues(alpha: 0.06)
                : AppColors.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md + 2,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: hasCount
                          ? AppColors.yellow.withValues(alpha: 0.22)
                          : AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: hasCount ? AppColors.yellowDark : AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (hasCount) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.yellow,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '$count',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm - 2),
                ],
                Icon(
                  Icons.chevron_right_rounded,
                  color: enabled ? AppColors.slate : AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchableSelectSheet<T> extends StatefulWidget {
  const _SearchableSelectSheet({
    required this.title,
    required this.searchHint,
    required this.items,
    required this.selectedIds,
    required this.itemToId,
    required this.itemToName,
    this.onClear,
  });

  final String title;
  final String searchHint;
  final List<T> items;
  final Set<int> selectedIds;
  final int Function(T) itemToId;
  final String Function(T) itemToName;
  final VoidCallback? onClear;

  @override
  State<_SearchableSelectSheet<T>> createState() =>
      _SearchableSelectSheetState<T>();
}

class _SearchableSelectSheetState<T> extends State<_SearchableSelectSheet<T>> {
  late final Set<int> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = Set<int>.from(widget.selectedIds);
  }

  List<T> get _filtered => widget.items
      .where((item) {
        if (_query.trim().isEmpty) return true;
        return widget
            .itemToName(item)
            .toLowerCase()
            .contains(_query.toLowerCase());
      })
      .toList(growable: false);

  void _toggle(int id) {
    setState(() {
      if (!_selected.add(id)) {
        _selected.remove(id);
      }
    });
  }

  void _clearAll() {
    widget.onClear?.call();
    setState(() => _selected.clear());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          Text(
            widget.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            decoration: InputDecoration(
              hintText: widget.searchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => setState(() => _query = ''),
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum resultado encontrado.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.slate,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final id = widget.itemToId(item);
                      final checked = _selected.contains(id);
                      return CheckboxListTile(
                        value: checked,
                        title: Text(widget.itemToName(item)),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (_) => _toggle(id),
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _selected.isEmpty ? null : _clearAll,
                  child: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
