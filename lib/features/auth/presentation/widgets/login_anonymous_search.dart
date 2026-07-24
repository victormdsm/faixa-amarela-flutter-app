import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Botão de acesso anônimo para busca de transporte escolar.
class LoginAnonymousSearch extends StatelessWidget {
  const LoginAnonymousSearch({
    super.key,
    required this.onSearch,
    this.enabled = true,
  });

  final VoidCallback onSearch;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: enabled ? onSearch : null,
      icon: const Icon(Icons.search_rounded, size: 20),
      label: const Text('Buscar transporte na minha região'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink.withValues(alpha: 0.7),
        minimumSize: const Size.fromHeight(44),
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}
