import '../models/notification.dart';

abstract interface class NotificationsRepository {
  Future<List<AppNotification>> getNotifications();

  Future<int> getUnreadCount();

  Future<void> markAsRead(int id);

  Future<void> markAllAsRead();
}
