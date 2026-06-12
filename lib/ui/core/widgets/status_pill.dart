import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../domain/models/enrollment.dart';

/// Small status indicator pill.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  factory StatusPill.fromStatus(EnrollmentStatus status) {
    final (label, color) = switch (status) {
      EnrollmentStatus.pending => ('Pendente', AppColors.yellow),
      EnrollmentStatus.active => ('Ativo', AppColors.success),
      EnrollmentStatus.rejected => ('Rejeitado', AppColors.danger),
      EnrollmentStatus.canceled => ('Cancelado', AppColors.muted),
    };
    return StatusPill(label: label, color: color);
  }

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
