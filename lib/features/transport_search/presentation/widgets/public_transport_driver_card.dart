import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/utils/whatsapp_launcher.dart';
import '../../domain/entities/public_transport_driver.dart';

/// Card de um motorista de transporte escolar publico encontrado na busca.
class PublicTransportDriverCard extends StatelessWidget {
  const PublicTransportDriverCard({super.key, required this.driver});

  final PublicTransportDriver driver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppNetworkAvatar(
              name: driver.name,
              imageUrl: driver.avatarUrl,
              radius: 30,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  if ((driver.information ?? '').isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      driver.information!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.slate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (driver.schools.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 13,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            driver.schools.take(2).join(' · '),
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
                  if (driver.districts.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            driver.districts.take(2).join(' · '),
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
            const SizedBox(width: AppSpacing.sm),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.yellowLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.yellowDark,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '-',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.yellowDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: (driver.cellPhone ?? '').trim().isEmpty
                      ? null
                      : () async {
                          final result = await WhatsAppLauncher.openChat(
                            phone: driver.cellPhone,
                            contactName: driver.name,
                          );
                          if (!context.mounted || result.success) return;
                          showAppSnackBar(
                            context,
                            message:
                                result.errorMessage ??
                                'Falha ao abrir o WhatsApp.',
                            type: AppFeedbackType.error,
                          );
                        },
                  child: const Text('Solicitar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
