import 'package:dio/dio.dart';

/// Unwraps NestJS {@link TransformInterceptor} wrapper `{"data": ...}`.
///
/// When the response body is exactly `{"data": <payload>}`, replaces
/// [Response.data] with `<payload>` so repositories work transparently.
class NestjsResponseUnwrapInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is Map<String, dynamic> &&
        data.length == 1 &&
        data.containsKey('data')) {
      response.data = data['data'];
    }
    handler.next(response);
  }
}
