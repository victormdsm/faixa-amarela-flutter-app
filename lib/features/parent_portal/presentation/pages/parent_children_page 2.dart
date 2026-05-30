import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/app_shared_widgets.dart';

class ParentChildrenPage extends StatelessWidget {
  const ParentChildrenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dependentes')),
      body: const AppEmptyState(
        message: 'Tela de dependentes em reconstruicao.',
        subtitle: 'Estrutura minima restaurada para app voltar a abrir.',
        icon: Icons.child_care_outlined,
      ),
    );
  }
}
