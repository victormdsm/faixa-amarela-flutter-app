import 'package:flutter/foundation.dart';

abstract final class BackendConfig {
  static const _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _envPusherKey = String.fromEnvironment('PUSHER_APP_KEY');
  static const _envPusherCluster = String.fromEnvironment('PUSHER_APP_CLUSTER');
  static const _envPusherHost = String.fromEnvironment('PUSHER_HOST');
  static const _envPusherPort = String.fromEnvironment('PUSHER_PORT');
  static const _envPusherScheme = String.fromEnvironment('PUSHER_SCHEME');
  static const _envPusherAuthEndpoint = String.fromEnvironment(
    'PUSHER_AUTH_ENDPOINT',
  );

  static String get apiBaseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _normalize(_envBaseUrl);
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api';
      default:
        return 'http://127.0.0.1:8000/api';
    }
  }

  static String get appBaseUrl {
    final api = apiBaseUrl;
    if (api.endsWith('/api')) {
      return api.substring(0, api.length - 4);
    }
    return api;
  }

  static String get pusherAppKey {
    final explicit = _envPusherKey.trim();
    if (explicit.isNotEmpty) return explicit;
    if (!kReleaseMode) return 'app-key';
    return '';
  }

  static String get pusherCluster => _envPusherCluster.trim();

  static String get pusherHost {
    if (_envPusherHost.trim().isNotEmpty) return _envPusherHost.trim();

    final apiHost = Uri.tryParse(appBaseUrl)?.host.trim() ?? '';
    if (apiHost.isNotEmpty) return apiHost;

    if (kIsWeb) return '127.0.0.1';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '10.0.2.2';
      default:
        return '127.0.0.1';
    }
  }

  static int get pusherPort {
    final parsed = int.tryParse(_envPusherPort.trim());
    return parsed ?? 8080;
  }

  static String get pusherScheme {
    final value = _envPusherScheme.trim().toLowerCase();
    if (value == 'https' || value == 'http') return value;
    return 'http';
  }

  static bool get pusherEncrypted => pusherScheme == 'https';

  static String get pusherAuthEndpoint {
    if (_envPusherAuthEndpoint.trim().isNotEmpty) {
      return _normalize(_envPusherAuthEndpoint);
    }
    return '$appBaseUrl/broadcasting/auth';
  }

  static String _normalize(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) return trimmed.substring(0, trimmed.length - 1);
    return trimmed;
  }
}
