import 'package:app_faixa_amarela/core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _dioError({
  int? statusCode,
  Object? data,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final requestOptions = RequestOptions(
    path: '/x',
    baseUrl: 'https://example.com',
  );
  return DioException(
    requestOptions: requestOptions,
    response: Response<dynamic>(
      requestOptions: requestOptions,
      statusCode: statusCode,
      data: data,
    ),
    type: type,
  );
}

void main() {
  group('ApiException.toFriendlyMessage', () {
    test('mantém mensagem pt-BR da whitelist do backend', () {
      final e = ApiException.fromDio(
        _dioError(statusCode: 401, data: {'message': 'Credenciais inválidas.'}),
      );
      expect(e.message, 'Credenciais inválidas.');
    });

    test('mantém a mensagem real do 400 do lookup por código (UUID-only)', () {
      const backendMessage =
          'Use o código da criança para buscar. Peça ao responsável que compartilhe o código no aplicativo.';
      final e = ApiException.fromDio(
        _dioError(statusCode: 400, data: {'message': backendMessage}),
      );
      expect(e.message, backendMessage);
      expect(e.statusCode, 400);
    });

    test('traduz Internal server error', () {
      final e = ApiException.fromDio(
        _dioError(statusCode: 500, data: {'message': 'Internal server error'}),
      );
      expect(e.message, 'Erro interno. Tente novamente em instantes.');
    });

    test('traduz Too Many Requests', () {
      final e = ApiException.fromDio(
        _dioError(statusCode: 429, data: {'message': 'Too Many Requests'}),
      );
      expect(e.message, 'Muitas tentativas. Aguarde um momento e tente de novo.');
    });

    test('traduz ThrottlerException', () {
      final e = ApiException.fromDio(
        _dioError(
          statusCode: 429,
          data: {'message': 'ThrottlerException: Too Many Requests'},
        ),
      );
      expect(e.message, 'Muitas tentativas. Aguarde um momento e tente de novo.');
    });

    test('429 sem corpo usa mensagem de limite de tentativas', () {
      final e = ApiException.fromDio(_dioError(statusCode: 429));
      expect(e.message, 'Muitas tentativas. Aguarde um momento e tente de novo.');
    });

    test('traduz validação de e-mail do class-validator', () {
      final e = ApiException.fromDio(
        _dioError(
          statusCode: 400,
          data: {'message': 'email must be an email'},
        ),
      );
      expect(e.message, 'Informe um e-mail válido.');
    });

    test('traduz mínimo de caracteres preservando o número', () {
      final e = ApiException.fromDio(
        _dioError(
          statusCode: 400,
          data: {
            'message': 'password must be longer than or equal to 8 characters',
          },
        ),
      );
      expect(e.message, 'Muito curto: mínimo de 8 caracteres.');
    });

    test('traduz property should not exist para dados inválidos', () {
      final e = ApiException.fromDio(
        _dioError(
          statusCode: 400,
          data: {'message': 'property role should not exist'},
        ),
      );
      expect(e.message, 'Dados inválidos. Revise os campos e tente novamente.');
    });

    test('junta array de validação em texto legível', () {
      final e = ApiException.fromDio(
        _dioError(
          statusCode: 400,
          data: {
            'message': [
              'email must be an email',
              'password should not be empty',
            ],
          },
        ),
      );
      expect(
        e.message,
        'Informe um e-mail válido.; Dados inválidos. Revise os campos e tente novamente.',
      );
    });

    test('traduz Route not found do Fastify', () {
      final e = ApiException.fromDio(
        _dioError(
          statusCode: 404,
          data: {
            'message': 'Route POST:/auth/login not found',
            'error': 'Not Found',
            'statusCode': 404,
          },
        ),
      );
      expect(e.message, 'Recurso não encontrado.');
    });

    test('corpo String HTML de proxy vira mensagem genérica de rede', () {
      final e = ApiException.fromDio(
        _dioError(
          statusCode: 502,
          data: '<!DOCTYPE html><html><head><title>502</title></head></html>',
        ),
      );
      expect(
        e.message,
        'Não foi possível falar com o servidor. Verifique sua conexão e tente novamente.',
      );
    });

    test('inglês desconhecido não vaza: fallback genérico pt-BR', () {
      final e = ApiException.fromDio(
        _dioError(
          statusCode: 500,
          data: {'message': 'Unexpected end of JSON input'},
        ),
      );
      expect(e.message, 'Não foi possível concluir a ação. Tente novamente.');
    });

    test('mantém pt-BR fora da whitelist', () {
      final e = ApiException.fromDio(
        _dioError(
          statusCode: 400,
          data: {'message': 'Operação não permitida neste momento.'},
        ),
      );
      expect(e.message, 'Operação não permitida neste momento.');
    });

    test('erro não-HTTP retorna fallback genérico sem texto cru', () {
      final e = ApiException.fromDio(Exception('socket hang up'));
      expect(e.message, 'Erro inesperado ao comunicar com a API.');
    });

    test('falha de conexão mantém mensagem de rede', () {
      final e = ApiException.fromDio(
        _dioError(type: DioExceptionType.connectionError),
      );
      expect(
        e.message,
        'Sem conexao com a internet ou servidor indisponivel no momento.',
      );
    });
  });
}
