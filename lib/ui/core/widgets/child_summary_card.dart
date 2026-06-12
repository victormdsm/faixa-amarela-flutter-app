import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../domain/models/child.dart';
import 'status_pill.dart';

/// Card displaying child summary. Never exposes CPF.
class ChildSummaryCard extends StatelessWidget {
  const ChildSummaryCard({
    super.key,
    required this.child,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  final Child child;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.yellowLight,
                    child: Text(
                      child.name.isNotEmpty ? child.name[0] : '?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${child.schoolName} • ${child.shiftName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.slate,
                          ),
                        ),
                        if (child.isInDebt) ...[
                          const SizedBox(height: AppSpacing.xs),
                          const StatusPill(
                            label: 'Inadimplente',
                            color: AppColors.danger,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (onEdit != null || onDelete != null) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (onEdit != null)
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Editar'),
                      ),
                    if (onDelete != null)
                      OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        label: const Text('Excluir'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
