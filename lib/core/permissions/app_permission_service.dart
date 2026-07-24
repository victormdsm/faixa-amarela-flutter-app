import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Centralizes location and notification permission checks/requests.
///
/// Uses [permission_handler] so the same flow works on Android and iOS.
/// The app already requests location via [Geolocator] when a route starts;
/// this service is used for the native first-launch permission request.
class AppPermissionService {
  const AppPermissionService();

  /// Whether the platform supports runtime permission dialogs.
  bool get _supportsRuntimePermissions =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Checks the current status of every permission needed by the app.
  Future<AppPermissionStatus> checkStatus() async {
    if (!_supportsRuntimePermissions) {
      return const AppPermissionStatus.granted();
    }

    final location = await Permission.location.status;
    final locationAlways = await Permission.locationAlways.status;
    final notifications = await Permission.notification.status;

    return AppPermissionStatus(
      location: location,
      locationAlways: locationAlways,
      notifications: notifications,
    );
  }

  /// Requests all permissions that are not already permanently granted.
  ///
  /// Returns `true` when every critical permission (location + notifications)
  /// is granted. Background location is requested separately because iOS and
  /// Android treat it as a two-step prompt.
  Future<bool> requestAll() async {
    if (!_supportsRuntimePermissions) return true;

    try {
      var location = await Permission.location.request();
      if (location.isPermanentlyDenied) return false;

      final notifications = await Permission.notification.request();
      if (notifications.isPermanentlyDenied) return false;

      // Background location is only useful on mobile; request it after the
      // user already granted foreground location.
      if (location.isGranted) {
        final always = await Permission.locationAlways.request();
        location = always.isGranted ? always : location;
      }

      return location.isGranted && notifications.isGranted;
    } catch (error, stackTrace) {
      developer.log(
        'Permission request failed: $error',
        name: 'app_permissions',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Opens the system settings for this app.
  Future<bool> openSettings() => openAppSettings();
}

/// Aggregated permission status used by [AppPermissionService].
class AppPermissionStatus {
  const AppPermissionStatus({
    required this.location,
    required this.locationAlways,
    required this.notifications,
  });

  const AppPermissionStatus.granted()
      : location = PermissionStatus.granted,
        locationAlways = PermissionStatus.granted,
        notifications = PermissionStatus.granted;

  final PermissionStatus location;
  final PermissionStatus locationAlways;
  final PermissionStatus notifications;

  bool get isLocationGranted =>
      location.isGranted || locationAlways.isGranted;

  bool get isBackgroundLocationGranted => locationAlways.isGranted;

  bool get areNotificationsGranted => notifications.isGranted;

  bool get isComplete => isLocationGranted && areNotificationsGranted;
}

/// Provider for [AppPermissionService].
final appPermissionServiceProvider = Provider<AppPermissionService>(
  (ref) => const AppPermissionService(),
);
