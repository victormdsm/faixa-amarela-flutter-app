import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException({required this.message, this.statusCode, this.data});

  final String message;
  final int? statusCode;
  final Object? data;

  // ---------------------------------------------------------------------------
  // Camada de tradução: converte mensagens cruas do backend em pt-BR amigável.
  // ---------------------------------------------------------------------------

  /// Fallback genérico para mensagens desconhecidas (em especial texto em
  /// inglês que nunca deve vazar para o usuário).
  static const String genericFallback =
      'Não foi possível concluir a ação. Tente novamente.';

  /// Fallback para corpos que não são mensagem de usuário (HTML de proxy etc.).
  static const String networkFallback =
      'Não foi possível falar com o servidor. Verifique sua conexão e tente novamente.';

  static const String tooManyAttemptsMessage =
      'Muitas tentativas. Aguarde um momento e tente de novo.';

  static const String _invalidDataMessage =
      'Dados inválidos. Revise os campos e tente novamente.';

  /// Whitelist de mensagens conhecidas do backend NestJS que já chegam em
  /// pt-BR (fonte: `throw ...Exception('...')` em `nestjs/src`). São mantidas
  /// exatamente como recebidas. Comparação em lowercase.
  static const Set<String> _knownPtBrMessages = {
    'acesso negado para este contexto.',
    'acesso negado.',
    'acesso restrito a motoristas.',
    'acesso restrito a superadministradores.',
    'admin não encontrado.',
    'aluno já está na rota.',
    'aluno não encontrado na rota.',
    'cpf já está em uso.',
    'conta inativa ou não ativada.',
    'conta já está ativada.',
    'conta não ativada ou inativa.',
    'credenciais inválidas.',
    'criança não encontrada.',
    'código de ativação expirado.',
    'código de ativação inválido.',
    'código de ativação já utilizado.',
    'email já está em uso.',
    'embarque não encontrado no manifesto.',
    'endereço não encontrado.',
    'esta solicitação já foi revisada.',
    'foto de perfil é obrigatória.',
    'foto é obrigatória.',
    'imagem do veículo é obrigatória.',
    'imagem é obrigatória.',
    'manifesto ativo não encontrado.',
    'matrícula não encontrada.',
    'motorista não encontrado.',
    'motorista não está revogado.',
    'notificação não encontrada.',
    'número máximo de tentativas excedido.',
    'perfil de motorista inativo.',
    'perfil de motorista não encontrado.',
    'publicidade não encontrada.',
    'refresh token inválido ou expirado.',
    'refresh token inválido.',
    'role admin não encontrada.',
    'role não encontrada.',
    'rota ativa não encontrada.',
    'rota não encontrada.',
    'senha atual incorreta.',
    'solicitação não encontrada.',
    "tipo deve ser 'avatar' ou 'vehicle'.",
    'token ausente.',
    'token expirado.',
    'token inválido ou expirado.',
    'token já utilizado.',
    'usuário não autenticado.',
    'usuário não encontrado.',
    'usuário não possui conta ativada.',
    'usuário não possui role admin.',
    'van ativa não encontrada.',
    'veículo não encontrado.',
    'você não está associado a esta criança.',
  };

  static final RegExp _htmlBody = RegExp(
    r'<\s*(!doctype|html|head|body|title|meta|div|p|span)\b',
    caseSensitive: false,
  );

  /// Tokens que indicam texto em inglês (word boundary, case-insensitive).
  /// Mantida conservadora para não falsos-positivos em pt-BR.
  static final RegExp _englishTokens = RegExp(
    r"\b(must|should|shall|cannot|can't|couldn't|wouldn't|failed|failure|"
    r'internal|unauthorized|forbidden|expected|unexpected|property|longer|'
    r'shorter|characters|throttler|unknown|denied|missing|invalid|error|'
    r'request|response|server|the)\b',
    caseSensitive: false,
  );

  /// Converte uma mensagem crua do backend em pt-BR amigável.
  ///
  /// Ordem de decisão:
  /// 1. Vazia → fallback genérico.
  /// 2. Whitelist pt-BR (backend NestJS) → mantida.
  /// 3. Corpo HTML (proxy/gateway) → mensagem genérica de rede.
  /// 4. Padrões ingleses conhecidos → tradução específica.
  /// 5. Texto desconhecido com cara de inglês → fallback genérico.
  /// 6. Demais casos (pt-BR fora da whitelist) → mantido como veio.
  static String toFriendlyMessage(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return genericFallback;

    if (_knownPtBrMessages.contains(text.toLowerCase())) return text;

    if (_htmlBody.hasMatch(text)) return networkFallback;

    final translated = _translateKnownEnglish(text);
    if (translated != null) return translated;

    if (_englishTokens.hasMatch(text)) return genericFallback;

    return text;
  }

  /// Padrões ingleses conhecidos (NestJS/Fastify/class-validator) → pt-BR.
  static String? _translateKnownEnglish(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('too many requests') ||
        lower.contains('throttlerexception')) {
      return tooManyAttemptsMessage;
    }
    if (lower.contains('internal server error')) {
      return 'Erro interno. Tente novamente em instantes.';
    }
    if (RegExp(r'route\s+\S+\s+not found', caseSensitive: false)
            .hasMatch(text) ||
        lower == 'not found') {
      return 'Recurso não encontrado.';
    }
    if (RegExp(r'must be an email', caseSensitive: false).hasMatch(text)) {
      return 'Informe um e-mail válido.';
    }
    final longer = RegExp(
      r'must be longer than or equal to (\d+) characters',
      caseSensitive: false,
    ).firstMatch(text);
    if (longer != null) {
      return 'Muito curto: mínimo de ${longer.group(1)} caracteres.';
    }
    final shorter = RegExp(
      r'must be shorter than or equal to (\d+) characters',
      caseSensitive: false,
    ).firstMatch(text);
    if (shorter != null) {
      return 'Muito longo: máximo de ${shorter.group(1)} caracteres.';
    }
    if (RegExp(r'property\s+\S+\s+should not exist', caseSensitive: false)
        .hasMatch(text)) {
      return _invalidDataMessage;
    }
    // Demais mensagens do class-validator (whitelist de validação do NestJS).
    if (RegExp(
      r'should not be empty|should not be null|must be a string|'
      r'must be a number|must be an integer|must be a boolean|'
      r'must be a valid|each value in|must be shorter|must be longer',
      caseSensitive: false,
    ).hasMatch(text)) {
      return _invalidDataMessage;
    }
    return null;
  }

  /// Extrai e traduz a mensagem crua do corpo da resposta.
  ///
  /// Arrays de validação (class-validator) são traduzidos item a item e
  /// juntados em texto legível.
  static String? _extractFriendlyMessage(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) {
      final parts = raw
          .map((e) => toFriendlyMessage(e.toString()))
          .where((e) => e.trim().isNotEmpty)
          .toList(growable: false);
      return parts.isEmpty ? null : parts.join('; ');
    }
    final text = raw.toString().trim();
    return text.isEmpty ? null : toFriendlyMessage(text);
  }

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

      // Prefer the backend's own message whenever it is available and safe.
      String? apiMessage;
      if (responseData is Map) {
        final map = Map<String, dynamic>.from(responseData);
        apiMessage = _extractFriendlyMessage(
          map['message'] ?? map['msg'] ?? map['error'],
        );
        if (apiMessage == null && map['errors'] is Map) {
          final errors = map['errors'] as Map;
          if (errors.values.isNotEmpty) {
            apiMessage = _extractFriendlyMessage(errors.values.first);
          }
        }
      } else if (responseData is String && responseData.trim().isNotEmpty) {
        apiMessage = _extractFriendlyMessage(responseData);
      }

      if (apiMessage != null && apiMessage.trim().isNotEmpty) {
        message = apiMessage;
      } else {
        if (statusCode == 401) {
          message = 'Sessao expirada. Faca login novamente.';
        } else if (statusCode == 403) {
          message = 'Voce nao tem permissao para esta acao.';
        } else if (statusCode == 404) {
          message = 'Recurso nao encontrado.';
        } else if (statusCode == 422) {
          message = 'Dados invalidos. Revise os campos e tente novamente.';
        } else if (statusCode == 429) {
          message = tooManyAttemptsMessage;
        } else if (isServerError) {
          message = 'Servidor indisponivel. Tente novamente em instantes.';
        }
      }

      return ApiException(
        message: message,
        statusCode: statusCode,
        data: responseData,
      );
    }

    // Erros que não são de HTTP nunca expõem texto cru (possível inglês).
    return ApiException(message: 'Erro inesperado ao comunicar com a API.');
  }

  @override
  String toString() => message;
}
