import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../network/api_exception.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

abstract final class AppErrorReporter {
  static String messageFor(Object error) {
    if (error is ApiException) return error.message;
    final apiError = ApiException.fromDio(error);
    if (apiError.message.isNotEmpty &&
        apiError.message != 'Erro inesperado ao comunicar com a API.') {
      return apiError.message;
    }
    return 'Ocorreu um erro inesperado. Tente novamente.';
  }

  static void report(
    Object error,
    StackTrace stackTrace, {
    String source = 'app',
    bool showSnack = false,
  }) {
    developer.log(
      '[$source] $error',
      error: error,
      stackTrace: stackTrace,
      name: 'faixa_amarela_error',
    );

    if (showSnack) {
      final messenger = rootScaffoldMessengerKey.currentState;
      if (messenger != null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(messageFor(error))));
      }
    }

    if (kDebugMode) {
      debugPrint('[$source] $error');
    }
  }
}
