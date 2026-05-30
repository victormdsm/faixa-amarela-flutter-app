import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/notifications/push_notifications.dart';
import '../features/notifications/presentation/providers/notification_providers.dart';
import '../features/tracking/presentation/providers/tracking_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class FaixaAmarelaApp extends ConsumerStatefulWidget {
  const FaixaAmarelaApp({super.key});

  @override
  ConsumerState<FaixaAmarelaApp> createState() => _FaixaAmarelaAppState();
}

class _FaixaAmarelaAppState extends ConsumerState<FaixaAmarelaApp> {
  void _refreshNotifications() {
    ref.invalidate(unreadNotificationsCountProvider);
    ref.invalidate(notificationsProvider);
  }

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(driverTrackingControllerProvider.notifier).initialize(),
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    FirebaseMessaging.onMessage.listen((message) {
      // FCM does not show notifications while in foreground — display it.
      PushNotifications.showForeground(message);
      _refreshNotifications();
    });
    FirebaseMessaging.onMessageOpenedApp.listen((_) => _refreshNotifications());
    Future<void>.microtask(() async {
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _refreshNotifications();
      }
    });
  }

  late final WidgetsBindingObserver _lifecycleObserver = _AppLifecycleObserver(
    onResumed: _refreshNotifications,
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Faixa Amarela',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}

class _AppLifecycleObserver with WidgetsBindingObserver {
  _AppLifecycleObserver({required this.onResumed});

  final VoidCallback onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}
