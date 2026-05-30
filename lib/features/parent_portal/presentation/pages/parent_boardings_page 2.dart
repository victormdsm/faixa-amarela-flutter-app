import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/app_shared_widgets.dart';

class ParentBoardingsPage extends StatelessWidget {
  const ParentBoardingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Embarques')),
      body: const AppEmptyState(
        message: 'Sem embarques para mostrar.',
        subtitle: 'Tela restaurada com estado seguro.',
        icon: Icons.hail_outlined,
      ),
    );
  }
}
