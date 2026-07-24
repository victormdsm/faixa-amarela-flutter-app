import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/app_shared_widgets.dart';

/// Estado inicial exibido antes de todos os filtros serem preenchidos.
class TransportSearchPrompt extends StatelessWidget {
  const TransportSearchPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: FaixaEmptyState(
        message: 'Preencha os filtros',
        icon: Icons.manage_search_rounded,
        subtitle:
            'Selecione escola, bairro e periodo para ver os motoristas disponiveis.',
      ),
    );
  }
}
