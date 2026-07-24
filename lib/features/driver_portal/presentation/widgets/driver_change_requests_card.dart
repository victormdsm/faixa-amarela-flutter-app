import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/driver_profile_change_request.dart';

/// Card com as solicitações recentes de alteração de perfil do motorista.
class DriverChangeRequestsCard extends StatelessWidget {
  const DriverChangeRequestsCard({super.key, required this.items});

  final List<DriverProfileChangeRequest> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.yellowLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solicitações recentes',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...items.map((item) {
            final status = item.status.toLowerCase();
            final note = (item.reviewNote ?? '').trim();
            final updatedAt =
                item.reviewedAt?.toLocal().toString() ??
                item.createdAt?.toLocal().toString() ??
                '';
            final statusLabel = switch (status) {
              'pending' => 'Pendente',
              'approved' => 'Aprovada',
              'rejected' => 'Reprovada',
              _ => 'Registrada',
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                note.isNotEmpty
                    ? '• $statusLabel ($updatedAt) - $note'
                    : '• $statusLabel ($updatedAt)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.slate,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
