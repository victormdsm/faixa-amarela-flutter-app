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
    this.emptyResultsText,
  });

  final String label;
  final String hintText;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onSelected;
  final VoidCallback? onCleared;
  final String? emptyResultsText;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        suffixIcon: onCleared == null
            ? null
            : IconButton(
                onPressed: onCleared,
                icon: const Icon(Icons.close_rounded),
              ),
      ),
      items: options.isEmpty
          ? [
              DropdownMenuItem<String>(
                value: null,
                enabled: false,
                child: Text(emptyResultsText ?? 'Nenhuma opcao disponivel'),
              ),
            ]
          : options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(option, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(growable: false),
      onChanged: options.isEmpty ? null : onSelected,
    );
  }
}
