import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/app_shared_widgets.dart';

class ParentRoutesPage extends StatelessWidget {
  const ParentRoutesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rotas')),
      body: const AppEmptyState(
        message: 'Nenhuma rota disponivel nesta versao.',
        subtitle: 'Portal dos pais ainda precisa de integracao completa.',
        icon: Icons.route_outlined,
      ),
    );
  }
}
