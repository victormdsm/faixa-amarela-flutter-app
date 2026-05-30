import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local-notification bridge for FCM.
///
/// The backend sends FCM messages with `android.notification.channel_id =
/// 'faixa_amarela_channel'`. Android 8+ drops notifications whose channel does
/// not exist, so we create it here. FCM also does NOT display notifications
/// while the app is in the foreground — we render those ourselves.
class PushNotifications {
  PushNotifications._();

  static const channelId = 'faixa_amarela_channel';
  static const _channelName = 'Faixa Amarela';
  static const _channelDescription =
      'Notificações de embarque, rotas e avisos.';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.high,
  );

  static bool _initialized = false;

  /// Creates the Android channel and initializes the local plugin. Safe to
  /// call multiple times.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// Displays a foreground FCM message as a system notification.
  static Future<void> showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return; // data-only message, nothing to show

    final title = notification.title ?? 'Faixa Amarela';
    final body = notification.body ?? '';

    await _plugin.show(
      notification.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }
}
