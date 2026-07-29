import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../../core/presentation/widgets/faixa_notification_tile.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../data/app_notification.dart';
import '../providers/notification_providers.dart';
import '../widgets/notification_detail_sheet.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.surfaceSoft,
        appBar: FaixaAppBar.screen(
          title: 'Notificações',
          actions: [
            IconButton(
              tooltip: 'Marcar todas como lidas',
              icon: const Icon(Icons.done_all_rounded),
              onPressed: () => _markAllAsRead(context, ref),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(notificationsProvider);
            ref.invalidate(unreadNotificationsCountProvider);
            await ref.read(notificationsProvider.future);
          },
          child: notifications.when(
            data: (page) {
              if (page.items.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: const [
                    SizedBox(height: 120),
                    FaixaEmptyState(
                      message: 'Nenhuma notificação',
                      icon: Icons.notifications_none_rounded,
                      subtitle:
                          'Alertas e avisos importantes aparecerão aqui.',
                    ),
                  ],
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                itemCount: page.items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final item = page.items[index];
                  return FaixaNotificationTile(
                    notification: item,
                    onTap: () => _openNotification(context, ref, item),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => FaixaErrorState(
              message: error.toString(),
              onRetry: () {
                ref.invalidate(notificationsProvider);
                ref.invalidate(unreadNotificationsCountProvider);
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Abre o detalhe da notificação em bottom sheet e a marca como lida.
  void _openNotification(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    unawaited(_markAsRead(context, ref, notification));
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => NotificationDetailSheet(notification: notification),
    );
  }

  Future<void> _markAsRead(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    if (!notification.isUnread) return;
    final auth = ref
        .read(appSessionControllerProvider)
        .session
        ?.authorizationHeader;
    if (auth == null) return;

    try {
      await ref
          .read(notificationRepositoryProvider)
          .markAsRead(auth, notification.id);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationsCountProvider);
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: 'Não foi possível marcar como lida: $e',
          type: AppFeedbackType.warning,
        );
      }
    }
  }

  Future<void> _markAllAsRead(BuildContext context, WidgetRef ref) async {
    final auth = ref
        .read(appSessionControllerProvider)
        .session
        ?.authorizationHeader;
    if (auth == null) return;

    await ref.read(notificationRepositoryProvider).markAllAsRead(auth);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationsCountProvider);
  }
}
