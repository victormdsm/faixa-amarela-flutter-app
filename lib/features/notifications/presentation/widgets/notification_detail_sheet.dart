import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../ui/core/widgets/status_pill.dart';
import '../../data/app_notification.dart';
import 'notification_type_visual.dart';

/// Bottom sheet com o detalhe completo de uma notificação.
///
/// Exibido ao tocar em um item da lista de notificações: título e corpo
/// completos (texto selecionável), badge de tipo, data/hora em pt-BR e
/// ícone contextual — o mesmo mapeamento de [notificationTypeVisual]
/// usado pelo tile da lista.
///
/// O payload `data` (JSON de deeplink/ação futura) é omitido de propósito:
/// não é informação para o usuário final.
class NotificationDetailSheet extends StatelessWidget {
  const NotificationDetailSheet({super.key, required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = notificationTypeVisual(notification.type);
    final badgeColor = visual.isAlert ? AppColors.danger : AppColors.yellowDark;

    return ConstrainedBox(
      constraints: BoxConstraints(
        // Mensagens longas rolam dentro do sheet, sem passar de ~70% da tela.
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: notification.isUnread
                      ? AppColors.yellow
                      : AppColors.surfaceSoft,
                  foregroundColor: AppColors.ink,
                  child: Icon(visual.icon, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      StatusPill(label: visual.label, color: badgeColor),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: AppColors.muted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  formatDateTime(notification.createdAt),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: notification.body.isNotEmpty
                    ? SelectableText(
                        notification.body,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.ink,
                          height: 1.5,
                        ),
                      )
                    : Text(
                        'Sem mensagem.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }
}
