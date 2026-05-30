import 'package:flutter/material.dart';

class SearchableSelectField extends StatelessWidget {
  const SearchableSelectField({
    super.key,
    required this.label,
    required this.hintText,
    required this.options,
    required this.onSelected,
    this.value,
    this.onCleared,
    this.emptyResultsText = 'Nenhuma opcao encontrada.',
    this.enabled = true,
  });

  final String label;
  final String hintText;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onSelected;
  final VoidCallback? onCleared;
  final String emptyResultsText;
  final bool enabled;

  Future<void> _openOptions(BuildContext context) async {
    if (!enabled) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _SearchableOptionsSheet(
        title: label,
        options: options,
        emptyResultsText: emptyResultsText,
      ),
    );

    if (result != null) {
      onSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.trim().isNotEmpty;

    return InkWell(
      onTap: () => _openOptions(context),
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: hasValue && onCleared != null
              ? IconButton(
                  tooltip: 'Limpar',
                  onPressed: onCleared,
                  icon: const Icon(Icons.close_rounded),
                )
              : const Icon(Icons.keyboard_arrow_down_rounded),
          enabled: enabled,
        ),
        child: Text(
          hasValue ? value! : hintText,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: hasValue
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}

class _SearchableOptionsSheet extends StatefulWidget {
  const _SearchableOptionsSheet({
    required this.title,
    required this.options,
    required this.emptyResultsText,
  });

  final String title;
  final List<String> options;
  final String emptyResultsText;

  @override
  State<_SearchableOptionsSheet> createState() =>
      _SearchableOptionsSheetState();
}

class _SearchableOptionsSheetState extends State<_SearchableOptionsSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = widget.options
        .where((option) => option.toLowerCase().contains(normalizedQuery))
        .toList(growable: false);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Buscar',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      widget.emptyResultsText,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final option = filtered[index];
                      return ListTile(
                        title: Text(option),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).pop(option),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
