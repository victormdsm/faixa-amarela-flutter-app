import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// Campo que abre um bottom sheet com busca e seleção single.
///
/// Útil para substituir dropdowns extensos de escolas, bairros etc. por uma
/// lista pesquisável. O callback [onSelected] recebe o valor selecionado ou
/// `null` quando o usuário limpa a seleção.
///
/// ```dart
/// FaixaSearchableSingleSelect(
///   label: 'Escola',
///   hintText: 'Selecione a escola',
///   options: schools,
///   value: selectedSchool,
///   searchHint: 'Buscar escola',
///   emptyResultsText: 'Nenhuma escola carregada da API.',
///   onSelected: (school) => setState(() => selectedSchool = school),
///   onCleared: () => setState(() => selectedSchool = null),
/// )
/// ```
class FaixaSearchableSingleSelect extends StatefulWidget {
  const FaixaSearchableSingleSelect({
    super.key,
    required this.label,
    required this.hintText,
    required this.options,
    required this.onSelected,
    this.value,
    this.onCleared,
    this.emptyResultsText,
    this.searchHint,
    this.title,
  });

  final String label;
  final String hintText;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onSelected;
  final VoidCallback? onCleared;
  final String? emptyResultsText;
  final String? searchHint;
  final String? title;

  @override
  State<FaixaSearchableSingleSelect> createState() =>
      _FaixaSearchableSingleSelectState();
}

class _FaixaSearchableSingleSelectState
    extends State<FaixaSearchableSingleSelect> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(covariant FaixaSearchableSingleSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newText = widget.value ?? '';
    if (widget.value != oldWidget.value && _controller.text != newText) {
      _controller.text = newText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openSheet() async {
    final result = await showModalBottomSheet<_SheetResult?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => _SingleSelectSheet(
        title: widget.title ?? widget.label,
        searchHint: widget.searchHint ?? 'Buscar',
        options: widget.options,
        selectedValue: widget.value,
        emptyResultsText: widget.emptyResultsText,
        onCleared: widget.onCleared,
      ),
    );

    if (result == null) return;

    if (result.cleared) {
      widget.onCleared?.call();
    } else {
      widget.onSelected(result.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      onTap: _openSheet,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        suffixIcon: widget.value != null && widget.onCleared != null
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: widget.onCleared,
              )
            : null,
      ),
    );
  }
}

class _SheetResult {
  const _SheetResult({this.value, this.cleared = false});

  final String? value;
  final bool cleared;
}

class _SingleSelectSheet extends StatefulWidget {
  const _SingleSelectSheet({
    required this.title,
    required this.searchHint,
    required this.options,
    this.selectedValue,
    this.emptyResultsText,
    this.onCleared,
  });

  final String title;
  final String searchHint;
  final List<String> options;
  final String? selectedValue;
  final String? emptyResultsText;
  final VoidCallback? onCleared;

  @override
  State<_SingleSelectSheet> createState() => _SingleSelectSheetState();
}

class _SingleSelectSheetState extends State<_SingleSelectSheet> {
  String _query = '';

  List<String> get _filtered => widget.options
      .where(
        (option) => _normalize(option).contains(_normalize(_query)),
      )
      .toList(growable: false);

  void _select(String value) => Navigator.of(context).pop(
        _SheetResult(value: value),
      );

  void _clear() => Navigator.of(context).pop(
        const _SheetResult(cleared: true),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;
    final hasSelection = widget.selectedValue != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const ValueKey('faixa_searchable_single_select_search_field'),
            autofocus: true,
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
          Flexible(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      _query.trim().isEmpty
                          ? (widget.emptyResultsText ??
                              'Nenhuma opção disponível.')
                          : 'Nenhum resultado encontrado.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.slate,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final option = filtered[index];
                      final selected = option == widget.selectedValue;
                      return ListTile(
                        title: Text(option),
                        trailing: selected
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppColors.yellowDark,
                              )
                            : null,
                        onTap: () => _select(option),
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (widget.onCleared != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: hasSelection ? _clear : null,
                    child: const Text('Limpar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Normaliza uma string para comparação insensível a caso e acentos.
///
/// Cobre os acentos mais comuns do português; não depende de pacotes
/// externos.
String _normalize(String value) {
  const from = 'áàãâäéèêëíìïîóòõôöúùûüçÁÀÃÂÄÉÈÊËÍÌÏÎÓÒÕÔÖÚÙÛÜÇ';
  const to = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';

  var result = value.toLowerCase().trim();
  for (var i = 0; i < from.length; i++) {
    result = result.replaceAll(from[i], to[i]);
  }
  return result;
}
