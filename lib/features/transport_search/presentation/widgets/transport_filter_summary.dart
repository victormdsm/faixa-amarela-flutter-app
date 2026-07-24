import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';

/// Resumo do estado dos filtros de busca de transporte.
class TransportFilterSummary extends StatelessWidget {
  const TransportFilterSummary({
    super.key,
    required this.hasRequiredFields,
    required this.resultsCount,
  });

  final bool hasRequiredFields;
  final int resultsCount;

  @override
  Widget build(BuildContext context) {
    final color = !hasRequiredFields
        ? AppColors.yellowDark
        : resultsCount > 0
        ? AppColors.success
        : AppColors.danger;
    final icon = !hasRequiredFields
        ? Icons.tune_rounded
        : resultsCount > 0
        ? Icons.check_circle_outline_rounded
        : Icons.warning_amber_rounded;
    final message = !hasRequiredFields
        ? 'Preencha todos os filtros para habilitar a busca.'
        : resultsCount > 0
        ? '$resultsCount opcao(oes) encontradas na API.'
        : 'Nenhum motorista encontrado para esta combinacao.';

    return AppStatusRow(icon: icon, color: color, message: message);
  }
}
