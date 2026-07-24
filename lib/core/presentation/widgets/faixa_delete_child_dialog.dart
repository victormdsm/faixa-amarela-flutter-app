import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../domain/models/child.dart';
import '../../../domain/models/enrollment.dart';

/// Fluxo de exclusão de dependente com dupla confirmação.
///
/// Exibe o primeiro diálogo ('Excluir dependente'); se confirmado, carrega a
/// matrícula ativa via [loadActiveEnrollment] e exibe o segundo diálogo,
/// avisando que a matrícula será cancelada quando houver vínculo.
///
/// Retorna `true` apenas quando o usuário confirma as duas etapas — cabe ao
/// chamador executar a exclusão em si. Exceções lançadas por
/// [loadActiveEnrollment] propagam para o chamador tratar.
Future<bool> showDeleteChildConfirmation(
  BuildContext context, {
  required Child child,
  required Future<Enrollment?> Function() loadActiveEnrollment,
}) async {
  final proceed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      title: const Text('Excluir dependente'),
      content: Text(
        'Deseja excluir ${child.name}?',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Continuar'),
        ),
      ],
    ),
  );
  if (proceed != true || !context.mounted) return false;

  final activeEnrollment = await loadActiveEnrollment();
  if (!context.mounted) return false;

  final String message;
  if (activeEnrollment != null) {
    message =
        '${child.name} está vinculado(a) ao motorista ${activeEnrollment.driverName}. '
        'Ao excluir, essa matrícula será cancelada. Deseja prosseguir?';
  } else {
    message = 'Tem certeza que deseja excluir ${child.name}?';
  }

  final confirmFinal = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      title: const Text('Confirmar exclusão'),
      content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(activeEnrollment != null ? 'Voltar' : 'Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.surface,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Confirmar exclusão'),
        ),
      ],
    ),
  );

  return confirmFinal == true;
}
