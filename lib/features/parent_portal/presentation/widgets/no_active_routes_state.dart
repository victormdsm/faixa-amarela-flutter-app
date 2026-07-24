import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/app_shared_widgets.dart';

/// Estado vazio exibido quando não há percursos ativos para acompanhar.
class NoActiveRoutesState extends StatelessWidget {
  const NoActiveRoutesState({super.key, required this.hasChildren});

  final bool hasChildren;

  @override
  Widget build(BuildContext context) {
    return FaixaEmptyState(
      message: hasChildren
          ? 'Nenhum percurso ativo agora'
          : 'Nenhum dependente cadastrado',
      icon: Icons.directions_bus_outlined,
      subtitle: hasChildren
          ? 'Quando o motorista do seu dependente iniciar uma rota, o mapa aparecerá aqui em tempo real.'
          : 'Cadastre um dependente na aba "Dependentes" para acompanhar os percursos.',
    );
  }
}
