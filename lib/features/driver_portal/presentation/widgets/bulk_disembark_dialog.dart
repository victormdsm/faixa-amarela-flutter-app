import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../domain/models/route_manifest.dart';

/// Exibe o dialog de confirmação para desembarcar todos os alunos na escola.
Future<void> showBulkDisembarkDialog(
  BuildContext context, {
  required RouteManifest route,
  required VoidCallback onConfirm,
}) async {
  final firstStopWithSchool = route.stops
      .where((s) => s.schoolId != null && s.schoolId! > 0)
      .firstOrNull;
  final schoolName =
      firstStopWithSchool?.schoolName ??
      route.stops.firstOrNull?.schoolName ??
      'escola';
  final schoolId = firstStopWithSchool?.schoolId ?? 0;

  if (schoolId <= 0) {
    showAppSnackBar(
      context,
      message: 'Nao foi possivel identificar a escola desta rota.',
      type: AppFeedbackType.warning,
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Entregar todos na escola'),
      content: Text(
        'Deseja marcar todos os alunos embarcados como entregues na escola ($schoolName)?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    onConfirm();
  }
}
