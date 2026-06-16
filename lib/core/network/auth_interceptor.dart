import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../storage/secure_token_storage.dart';
import 'backend_config.dart';

/// Global stream used to notify the app layer when the session is terminated.
/// The interceptor lives in core and cannot depend on auth feature state.
class AuthLogoutStream {
  static final _controller = StreamController<void>.broadcast();
  static Stream<void> get stream => _controller.stream;
  static void emit() => _controller.add(null);
}

/// Attaches the access token to every outgoing request and transparently
/// refreshes it when the backend returns 401.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required SecureTokenStorage secureStorage,
    void Function()? onUnauthorized,
  }) : _dio = dio,
       _secureStorage = secureStorage,
       _onUnauthorized = onUnauthorized;

  final Dio _dio;
  final SecureTokenStorage _secureStorage;
  final void Function()? _onUnauthorized;

  static final _refreshLock = Lock();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    if (response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Avoid refreshing requests that are themselves public auth endpoints.
    final path = err.requestOptions.path;
    final isPublicAuthPath = path == '/auth/refresh' ||
        path == '/auth/logout' ||
        path == '/auth/user/login' ||
        path == '/auth/driver/login' ||
        path == '/auth/admin/login' ||
        path == '/auth/user/register' ||
        path == '/auth/activate' ||
        path == '/auth/forgot-password' ||
        path == '/auth/reset-password';
    if (isPublicAuthPath) {
      // Public auth failures (e.g. wrong password) must keep the original
      // backend message and must not trigger a logout/refresh cycle.
      handler.next(err);
      return;
    }

    // If this request is already a retry after a refresh, do not attempt
    // another refresh to avoid infinite loops when the backend keeps
    // rejecting the access token.
    if (err.requestOptions.extra['_authRetry'] == true) {
      developer.log(
        'Request failed with 401 after refresh; aborting retry loop.',
        name: 'auth_interceptor',
      );
      await _clearSession();
      handler.reject(err);
      return;
    }

    try {
      final refreshed = await _refreshLock.synchronized(_doRefresh);
      if (!refreshed) {
        await _clearSession();
        handler.reject(err);
        return;
      }

      final token = await _secureStorage.readAccessToken();
      if (token == null || token.isEmpty) {
        await _clearSession();
        handler.reject(err);
        return;
      }

      final options = err.requestOptions.copyWith(
        extra: {...err.requestOptions.extra, '_authRetry': true},
      );
      options.headers['Authorization'] = 'Bearer $token';
      final retried = await _dio.fetch<dynamic>(options);
      handler.resolve(retried);
    } catch (error) {
      await _clearSession();
      handler.reject(err);
    }
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _secureStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      developer.log(
        'No refresh token available; clearing session.',
        name: 'auth_interceptor',
      );
      return false;
    }

    // Use a standalone Dio instance to avoid running this interceptor again.
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: BackendConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    try {
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final data = response.data;
      if (data == null) return false;
      final payload = data['data'] as Map<String, dynamic>? ?? data;

      final accessToken = (payload['access_token'] ?? payload['accessToken'])?.toString();
      final newRefreshToken = (payload['refresh_token'] ?? payload['refreshToken'])?.toString();

      if (accessToken == null || accessToken.isEmpty) return false;

      await _secureStorage.writeAccessToken(accessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _secureStorage.writeRefreshToken(newRefreshToken);
      }
      return true;
    } on DioException catch (e) {
      developer.log(
        'Refresh request failed: ${e.message}',
        name: 'auth_interceptor',
        error: e,
      );
      return false;
    } catch (e) {
      developer.log(
        'Unexpected refresh error: $e',
        name: 'auth_interceptor',
        error: e,
      );
      return false;
    }
  }

  Future<void> _clearSession() async {
    await _secureStorage.clearAll();
    _onUnauthorized?.call();
    AuthLogoutStream.emit();
  }
}

/// Simple mutual exclusion helper.
class Lock {
  Future<void>? _pending;

  Future<T> synchronized<T>(Future<T> Function() task) async {
    while (_pending != null) {
      await _pending;
    }

    late final T result;
    _pending = () async {
      result = await task();
    }().whenComplete(() => _pending = null);

    await _pending;
    return result;
  }
}
