import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(driverTrackingControllerProvider.notifier).initialize(),
    );
    FirebaseMessaging.onMessage.listen((_) {
      ref.invalidate(unreadNotificationsCountProvider);
      ref.invalidate(notificationsProvider);
    });
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
