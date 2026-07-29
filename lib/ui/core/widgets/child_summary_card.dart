import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../domain/models/child.dart';
import 'status_pill.dart';

/// Card displaying child summary. Never exposes CPF.
class ChildSummaryCard extends StatelessWidget {
  const ChildSummaryCard({
    super.key,
    required this.child,
    this.schoolName,
    this.hasRoute,
    this.onEdit,
    this.onTap,
  });

  final Child child;
  final String? schoolName;
  final bool? hasRoute;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routeStatus = hasRoute;

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
                  AppNetworkAvatar(
                    name: child.name,
                    imageUrl: child.photoUrl,
                    radius: 26,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        if (schoolName != null && schoolName!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 14,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  schoolName!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.slate,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (routeStatus != null || child.isInDebt) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (routeStatus != null)
                      StatusPill(
                        label: routeStatus ? 'Com transporte' : 'Sem rota',
                        color: routeStatus ? AppColors.success : AppColors.muted,
                      ),
                    if (child.isInDebt)
                      const StatusPill(
                        label: 'Inadimplente',
                        color: AppColors.danger,
                      ),
                  ],
                ),
              ],
              if (onEdit != null) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.icon(
                      // O tema global define largura mínima infinita nos
                      // FilledButtons; dentro deste Row (filho não-flex) o
                      // botão precisa de largura mínima finita.
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar'),
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
