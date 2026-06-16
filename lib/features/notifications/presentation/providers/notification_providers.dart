import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/network_providers.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../data/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(dioProvider)),
);

String _requireAuthHeader(Ref ref) {
  final session = ref.watch(appSessionControllerProvider).session;
  if (session == null) {
    throw ApiException(message: 'Sessao expirada. Faca login novamente.');
  }
  return session.authorizationHeader;
}

final notificationsProvider = FutureProvider.autoDispose((ref) async {
  final auth = _requireAuthHeader(ref);
  return ref.watch(notificationRepositoryProvider).notifications(auth);
});

final unreadNotificationsCountProvider = FutureProvider.autoDispose((
  ref,
) async {
  final auth = _requireAuthHeader(ref);
  return ref.watch(notificationRepositoryProvider).unreadCount(auth);
});

final pushRegistrationServiceProvider = Provider<PushRegistrationService>(
  (ref) => PushRegistrationService(ref),
);

class PushRegistrationService {
  PushRegistrationService(this._ref);

  final Ref _ref;

  bool _listeningForRefresh = false;

  Future<void> registerCurrentDevice(String authHeader) async {
    try {
      final messaging = FirebaseMessaging.instance;

      // iOS/macOS: requestPermission is required to get a valid APNs token.
      // Android: rely on the native notification permission flow elsewhere
      // (e.g. route tracking) to avoid duplicating the Android 13+ permission
      // prompt with FirebaseMessaging.requestPermission.
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        await messaging.requestPermission(alert: true, badge: true, sound: true);
      }

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        developer.log(
          'FCM did not return a device token; skipping backend registration.',
          name: 'push_registration',
        );
        return;
      }

      await _ref
          .read(notificationRepositoryProvider)
          .saveDeviceToken(authHeader, token);

      if (!_listeningForRefresh) {
        _listeningForRefresh = true;
        messaging.onTokenRefresh.listen((nextToken) {
          if (nextToken.isEmpty) return;
          final session = _ref.read(appSessionControllerProvider).session;
          if (session == null) return;
          _ref
              .read(notificationRepositoryProvider)
              .saveDeviceToken(session.authorizationHeader, nextToken);
        });
      }
    } catch (error, stackTrace) {
      // Login must not fail because push permission or Firebase is unavailable.
      developer.log(
        'Push registration failed: $error',
        name: 'push_registration',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
