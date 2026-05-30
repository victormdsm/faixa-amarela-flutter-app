import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException({required this.message, this.statusCode, this.data});

  final String message;
  final int? statusCode;
  final Object? data;

  factory ApiException.fromDio(Object error) {
    if (error is DioException) {
      final responseData = error.response?.data;
      final statusCode = error.response?.statusCode;
      String message = 'Falha de comunicacao com o servidor.';

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Tempo de resposta esgotado. Tente novamente.';
          break;
        case DioExceptionType.connectionError:
          message =
              'Sem conexao com a internet ou servidor indisponivel no momento.';
          break;
        case DioExceptionType.cancel:
          message = 'Requisicao cancelada.';
          break;
        default:
          break;
      }

      if (statusCode == 413) {
        return ApiException(
          message:
              'Arquivo muito grande para envio. Reduza a foto (ou envie sem foto) e tente novamente.',
          statusCode: statusCode,
          data: responseData,
        );
      }

      final isServerError = statusCode != null && statusCode >= 500;

      if (statusCode == 401) {
        message = 'Sessao expirada. Faca login novamente.';
      } else if (statusCode == 403) {
        message = 'Voce nao tem permissao para esta acao.';
      } else if (statusCode == 404) {
        message = 'Recurso nao encontrado.';
      } else if (statusCode == 422) {
        message = 'Dados invalidos. Revise os campos e tente novamente.';
      } else if (isServerError) {
        message = 'Servidor indisponivel. Tente novamente em instantes.';
      }

      // For 5xx errors, never expose internal server details to the user.
      if (!isServerError) {
        if (responseData is Map) {
          final map = Map<String, dynamic>.from(responseData);
          final apiMessage = map['message'] ?? map['msg'];
          if (apiMessage is String && apiMessage.trim().isNotEmpty) {
            message = apiMessage;
          } else if (map['errors'] is Map) {
            final errors = map['errors'] as Map;
            if (errors.values.isNotEmpty) {
              final first = errors.values.first;
              if (first is List && first.isNotEmpty) {
                message = first.first.toString();
              } else if (first != null) {
                message = first.toString();
              }
            }
          }
        } else if (responseData is String && responseData.trim().isNotEmpty) {
          message = responseData;
        }
      }

      return ApiException(
        message: message,
        statusCode: statusCode,
        data: responseData,
      );
    }

    return ApiException(message: 'Erro inesperado ao comunicar com a API.');
  }

  @override
  String toString() => message;
}
