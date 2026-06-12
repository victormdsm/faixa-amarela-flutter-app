import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs only non-sensitive request metadata. Never logs request/response bodies,
/// headers, or tokens. Only active in debug/profile builds.
class SafeLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[HTTP] ${options.method} ${options.path}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[HTTP] ${response.statusCode} ${response.requestOptions.path}');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(
        '[HTTP] ERROR ${err.response?.statusCode} ${err.requestOptions.path}: ${err.type}',
      );
    }
    super.onError(err, handler);
  }
}
