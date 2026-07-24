import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../features/notifications/data/app_notification.dart';

/// Tile de notificação padronizado.
///
/// Fundo amarelo-claro para não lidas e branco para lidas.
/// Exibe avatar com ícone contextual, título, corpo, data/hora e indicador.
///
/// Pode ser construído a partir de um [AppNotification]:
/// ```dart
/// FaixaNotificationTile(notification: item)
/// ```
///
/// Ou com os campos desmembrados:
/// ```dart
/// FaixaNotificationTile(
///   title: item.title,
///   body: item.body,
///   type: item.type,
///   createdAt: item.createdAt,
///   isUnread: item.isUnread,
/// )
/// ```
class FaixaNotificationTile extends StatelessWidget {
  const FaixaNotificationTile({
    super.key,
    this.notification,
    this.title,
    this.body,
    this.type,
    this.createdAt,
    this.isUnread,
    this.onTap,
  }) : assert(
         notification != null ||
             (title != null &&
                 body != null &&
                 type != null &&
                 isUnread != null),
         'Forneça notification ou title/body/type/isUnread.',
       );

  final AppNotification? notification;
  final String? title;
  final String? body;
  final String? type;
  final DateTime? createdAt;
  final bool? isUnread;
  final VoidCallback? onTap;

  String get _title => notification?.title ?? title!;
  String get _body => notification?.body ?? body!;
  String get _type => notification?.type ?? type!;
  DateTime? get _createdAt => notification?.createdAt ?? createdAt;
  bool get _isUnread => notification?.isUnread ?? isUnread!;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: _isUnread ? AppColors.yellowLight : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _isUnread
                    ? AppColors.yellow
                    : AppColors.surfaceSoft,
                foregroundColor: AppColors.ink,
                child: Icon(_iconFor(_type), size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: _isUnread
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    if (_body.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.slate,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _formatDate(_createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isUnread)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: AppColors.yellow,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'boarded' => Icons.directions_bus_rounded,
      'disembarked' => Icons.home_rounded,
      'arrived' => Icons.location_on_rounded,
      'delayed' => Icons.schedule_rounded,
      'breakdown' || 'flat_tire' || 'accident' => Icons.warning_rounded,
      'driver_profile_change_reviewed' => Icons.verified_user_rounded,
      'payment' || 'billing' || 'invoice' => Icons.receipt_long_rounded,
      'system' => Icons.info_outline_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
