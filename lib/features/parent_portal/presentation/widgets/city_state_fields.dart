import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/catalog_option.dart';

/// UFs brasileiras para o seletor de estado (2 letras, como no DTO).
const List<String> kBrazilStates = [
  'AC',
  'AL',
  'AP',
  'AM',
  'BA',
  'CE',
  'DF',
  'ES',
  'GO',
  'MA',
  'MT',
  'MS',
  'MG',
  'PA',
  'PB',
  'PR',
  'PE',
  'PI',
  'RJ',
  'RN',
  'RS',
  'RO',
  'RR',
  'SC',
  'SP',
  'SE',
  'TO',
];

/// Seletor de cidade (catálogo `/catalogs/cities`) com busca em bottom sheet.
///
/// Segue o padrão visual do `FaixaSearchableSelect` (sheet com busca), mas
/// com seleção ÚNICA: tocar na cidade confirma e fecha. Integra com [Form]
/// via [FormField], então o [validator] funciona como nos demais campos.
class CitySelectField extends StatelessWidget {
  const CitySelectField({
    super.key,
    required this.citiesAsync,
    required this.value,
    required this.onChanged,
    this.validator,
    this.onRetry,
  });

  final AsyncValue<List<CatalogOption>> citiesAsync;
  final CatalogOption? value;
  final ValueChanged<CatalogOption?> onChanged;
  final String? Function(CatalogOption?)? validator;

  /// Chamado ao tocar em "Tentar novamente" quando o catálogo falha.
  final VoidCallback? onRetry;

  Future<void> _openSheet(
    BuildContext context,
    List<CatalogOption> items,
  ) async {
    final result = await showModalBottomSheet<CatalogOption>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _CitySelectSheet(items: items, selectedId: value?.id),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<CatalogOption>(
      // A key reancora o FormField quando a seleção muda fora (ex.: reverse
      // geocoding preenchendo a cidade), mantendo o valor validado em dia.
      key: ValueKey(value?.id ?? 0),
      initialValue: value,
      validator: validator,
      builder: (field) {
        final theme = Theme.of(context);
        final hasError = field.hasError;

        final Widget content = switch (citiesAsync) {
          AsyncData(:final value) => _CityFieldContent(
            label: 'Cidade',
            text: this.value?.name ?? 'Selecione a cidade',
            isPlaceholder: this.value == null,
            hasError: hasError,
            onTap: () => _openSheet(context, value),
          ),
          AsyncError() => _CityFieldContent(
            label: 'Cidade',
            text: 'Erro ao carregar cidades.',
            isPlaceholder: true,
            hasError: true,
            trailing: onRetry == null
                ? null
                : IconButton(
                    tooltip: 'Tentar novamente',
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                  ),
          ),
          _ => const _CityFieldContent(
            label: 'Cidade',
            text: 'Carregando cidades...',
            isPlaceholder: true,
            showProgress: true,
          ),
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            content,
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.xs,
                  left: AppSpacing.md,
                ),
                child: Text(
                  field.errorText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CityFieldContent extends StatelessWidget {
  const _CityFieldContent({
    required this.label,
    required this.text,
    this.isPlaceholder = false,
    this.hasError = false,
    this.showProgress = false,
    this.onTap,
    this.trailing,
  });

  final String label;
  final String text;
  final bool isPlaceholder;
  final bool hasError;
  final bool showProgress;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: hasError ? AppColors.danger : AppColors.border,
            ),
            color: AppColors.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_city_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isPlaceholder
                              ? AppColors.muted
                              : AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showProgress)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ?trailing,
                if (trailing == null && !showProgress)
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.slate,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CitySelectSheet extends StatefulWidget {
  const _CitySelectSheet({required this.items, this.selectedId});

  final List<CatalogOption> items;
  final int? selectedId;

  @override
  State<_CitySelectSheet> createState() => _CitySelectSheetState();
}

class _CitySelectSheetState extends State<_CitySelectSheet> {
  String _query = '';

  List<CatalogOption> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items
        .where((c) => c.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;
    // Ver faixa_searchable_single_select.dart: sem o inset do teclado o
    // conteúdo do sheet fica escondido atrás dele ao digitar.
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg + keyboardInset,
      ),
      child: Column(
        children: [
          Text(
            'Selecione a cidade',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Buscar cidade',
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
                      'Nenhuma cidade encontrada.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.slate,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final city = filtered[index];
                      final selected = city.id == widget.selectedId;
                      return ListTile(
                        title: Text(city.name),
                        trailing: selected
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppColors.yellowDark,
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(city),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Seletor de UF (2 letras) — dropdown simples com as 27 UFs.
class UfSelectField extends StatelessWidget {
  const UfSelectField({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
    this.enabled = true,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  /// Quando false, o dropdown fica desabilitado (valor apenas exibido).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'UF',
        prefixIcon: Icon(Icons.flag_outlined, size: 18),
      ),
      items: kBrazilStates
          .map((uf) => DropdownMenuItem(value: uf, child: Text(uf)))
          .toList(growable: false),
      onChanged: enabled ? onChanged : null,
      validator: validator,
    );
  }
}
