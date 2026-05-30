import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'core/error/app_error_reporter.dart';
import 'core/notifications/push_notifications.dart';
import 'features/auth/data/session_storage.dart';
import 'features/catalog/data/catalog_repository.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Future.wait([
    SessionStorage.openBox(),
    CatalogRepository.openCacheBox(),
  ]);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppErrorReporter.report(
      details.exception,
      details.stack ?? StackTrace.current,
      source: 'flutter_error',
      showSnack: true,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppErrorReporter.report(
      error,
      stack,
      source: 'platform_dispatcher',
      showSnack: true,
    );
    return true;
  };

  ErrorWidget.builder = (details) => Material(
    color: Colors.white,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Ops. Ocorreu uma falha nesta tela.\nTente voltar e abrir novamente.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black87),
        ),
      ),
    ),
  );

  await runZonedGuarded(
    () async {
      await Firebase.initializeApp();
      await PushNotifications.init();
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      runApp(const ProviderScope(child: FaixaAmarelaApp()));
    },
    (error, stack) {
      AppErrorReporter.report(
        error,
        stack,
        source: 'zoned_guarded',
        showSnack: true,
      );
    },
  );
}
