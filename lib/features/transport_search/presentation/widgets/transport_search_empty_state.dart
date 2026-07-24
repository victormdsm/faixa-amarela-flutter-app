import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/utils/whatsapp_launcher.dart';

/// Estado vazio exibido quando nenhum motorista é encontrado para os
/// filtros selecionados.
class TransportSearchEmptyState extends StatelessWidget {
  const TransportSearchEmptyState({
    super.key,
    this.schoolName,
    this.neighborhoodName,
    this.periodLabel,
  });

  final String? schoolName;
  final String? neighborhoodName;
  final String? periodLabel;

  @override
  Widget build(BuildContext context) {
    return FaixaEmptyState(
      message: 'Nenhum motorista encontrado',
      icon: Icons.search_off_rounded,
      subtitle:
          'Nao ha motoristas cadastrados para essa combinacao de escola, bairro e periodo.',
      actionLabel: 'Contatar SINPROVETE',
      onAction: () async {
        final message = [
          'Ola, sou usuario(a) do app Faixa Amarela e nao encontrei transporte disponivel.',
          'Gostaria de confirmar com o sindicato (SINPROVETE).',
          '',
          'Minha busca:',
          if ((schoolName ?? '').trim().isNotEmpty)
            'Escola: ${schoolName!.trim()}',
          if ((neighborhoodName ?? '').trim().isNotEmpty)
            'Bairro: ${neighborhoodName!.trim()}',
          if ((periodLabel ?? '').trim().isNotEmpty)
            'Periodo: ${periodLabel!.trim()}',
        ].join('\n');
        final result = await WhatsAppLauncher.openChat(
          phone: '+55 45 99128-6668',
          contactName: 'SINPROVETE',
          message: message,
        );
        if (!context.mounted || result.success) return;
        showAppSnackBar(
          context,
          message:
              result.errorMessage ?? 'Falha ao abrir contato da SINPROVETE.',
          type: AppFeedbackType.error,
        );
      },
    );
  }
}
