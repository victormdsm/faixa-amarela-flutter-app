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
    // APP-19: só desembrulha quando `data` é a ÚNICA chave do objeto —
    // payloads legítimos que contêm um campo `data` próprio (ex.: a entidade
    // notification retornada por PUT /notifications/:id/read) não podem ser
    // confundidos com o envelope. Envelopes paginados `{ data, meta }` também
    // são preservados (length > 1) para o repository acessar os metadados.
    if (data is Map<String, dynamic> &&
        data.length == 1 &&
        data.containsKey('data')) {
      response.data = data['data'];
    }
    handler.next(response);
  }
}
