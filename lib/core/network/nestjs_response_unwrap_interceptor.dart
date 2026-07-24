import 'package:dio/dio.dart';

/// Unwraps NestJS [ResponseInterceptor] envelope `{"data": <payload>}`.
///
/// The backend wraps successful responses as `{ data: <payload>, meta?: {...} }`.
/// When the response body contains a `data` key and the payload is not already
/// the raw response the caller expects, replaces [Response.data] with the
/// payload so repositories work transparently.
class NestjsResponseUnwrapInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    // O backend envolve respostas genéricas em `{ data: <payload> }`.
    // Alguns endpoints (paginação, busca pública) já retornam seu próprio
    // contrato `{ data: [...], meta: {...} }`. Quando `meta` está presente,
    // preservamos o envelope original para que o repository possa acessar
    // tanto a lista quanto os metadados de paginação.
    if (data is Map<String, dynamic> &&
        data.containsKey('data') &&
        !data.containsKey('meta')) {
      response.data = data['data'];
    }
    handler.next(response);
  }
}
