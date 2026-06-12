import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/secure_token_storage.dart';

/// Global stream used to notify the app layer when a 401 is received.
/// The interceptor lives in core and cannot depend on auth feature state.
class AuthLogoutStream {
  static final _controller = StreamController<void>.broadcast();
  static Stream<void> get stream => _controller.stream;
  static void emit() => _controller.add(null);
}

/// Attaches the access token to every outgoing request and clears storage on 401.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureTokenStorage secureStorage,
    void Function()? onUnauthorized,
  }) : _secureStorage = secureStorage,
       _onUnauthorized = onUnauthorized;

  final SecureTokenStorage _secureStorage;
  final void Function()? _onUnauthorized;

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
    if (err.response?.statusCode == 401) {
      await _secureStorage.clearAll();
      _onUnauthorized?.call();
      AuthLogoutStream.emit();
    }
    handler.next(err);
  }
}
