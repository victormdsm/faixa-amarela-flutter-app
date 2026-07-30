import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/error/app_error_reporter.dart';
import '../core/network/auth_interceptor.dart';
import '../core/notifications/push_notifications.dart';
import '../core/permissions/app_permission_service.dart';
import '../features/ads/presentation/providers/ads_providers.dart';
import '../features/auth/presentation/state/app_session_controller.dart';
import '../features/driver_portal/presentation/providers/driver_portal_providers.dart';
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
  late final StreamSubscription<void> _logoutSubscription;

  void _refreshNotifications() {
    ref.invalidate(unreadNotificationsCountProvider);
    ref.invalidate(notificationsProvider);
    // APP-29: anúncios também valem por sessão/papel — recarrega no
    // retorno ao foreground, seguindo o padrão das notificações.
    ref.invalidate(adsProvider);
  }

  void _handleFcmData(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    if (type == 'driver_profile_change_reviewed') {
      ref.invalidate(driverProfileProvider);
    }
  }

  @override
  void initState() {
    super.initState();
    _logoutSubscription = AuthLogoutStream.stream.listen((_) {
      ref.read(appSessionControllerProvider.notifier).clear();
    });
    Future<void>.microtask(
      () => ref.read(appSessionControllerProvider.notifier).loadFromStorage(),
    );
    Future<void>.microtask(
      () => ref.read(driverTrackingControllerProvider.notifier).initialize(),
    );
    // Request location and notification permissions natively on first launch.
    // This is intentionally fire-and-forget: the app must not block on the
    // user's response and should continue to the login/dashboard normally.
    Future<void>.microtask(() async {
      try {
        await ref.read(appPermissionServiceProvider).requestAll();
      } catch (error, stack) {
        AppErrorReporter.report(
          error,
          stack,
          source: 'permission_request',
          showSnack: false,
        );
      }
    });
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    FirebaseMessaging.onMessage.listen((message) {
      try {
        PushNotifications.showForeground(message);
        _refreshNotifications();
        _handleFcmData(message.data);
      } catch (error, stack) {
        AppErrorReporter.report(
          error,
          stack,
          source: 'fcm_foreground',
          showSnack: true,
        );
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      try {
        _refreshNotifications();
        _handleFcmData(message.data);
      } catch (error, stack) {
        AppErrorReporter.report(
          error,
          stack,
          source: 'fcm_opened_app',
          showSnack: false,
        );
      }
    });
    Future<void>.microtask(() async {
      try {
        final initialMessage = await FirebaseMessaging.instance
            .getInitialMessage();
        if (initialMessage != null) {
          _refreshNotifications();
        }
      } catch (error, stack) {
        AppErrorReporter.report(
          error,
          stack,
          source: 'fcm_initial_message',
          showSnack: false,
        );
      }
    });
  }

  late final WidgetsBindingObserver _lifecycleObserver = _AppLifecycleObserver(
    onResumed: _refreshNotifications,
  );

  @override
  void dispose() {
    _logoutSubscription.cancel();
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
      scaffoldMessengerKey: rootScaffoldMessengerKey,
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
