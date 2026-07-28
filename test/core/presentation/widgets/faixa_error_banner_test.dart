import 'package:app_faixa_amarela/core/presentation/widgets/app_shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inferFaixaErrorType', () {
    test('rede', () {
      expect(
        inferFaixaErrorType(
          'Sem conexao com a internet ou servidor indisponivel no momento.',
        ),
        FaixaErrorType.network,
      );
      expect(
        inferFaixaErrorType('Tempo de resposta esgotado. Tente novamente.'),
        FaixaErrorType.network,
      );
    });

    test('autenticação', () {
      expect(
        inferFaixaErrorType('Sessao expirada. Faca login novamente.'),
        FaixaErrorType.auth,
      );
      expect(
        inferFaixaErrorType('Credenciais inválidas.'),
        FaixaErrorType.auth,
      );
    });

    test('validação', () {
      expect(
        inferFaixaErrorType('Informe um e-mail válido.'),
        FaixaErrorType.validation,
      );
      expect(
        inferFaixaErrorType('Dados inválidos. Revise os campos e tente novamente.'),
        FaixaErrorType.validation,
      );
    });

    test('servidor', () {
      expect(
        inferFaixaErrorType('Erro interno. Tente novamente em instantes.'),
        FaixaErrorType.server,
      );
      expect(
        inferFaixaErrorType('Muitas tentativas. Aguarde um momento e tente de novo.'),
        FaixaErrorType.server,
      );
    });

    test('desconhecido', () {
      expect(inferFaixaErrorType('Algo inesperado.'), FaixaErrorType.unknown);
    });
  });

  group('FaixaErrorBanner', () {
    Future<void> pumpBanner(
      WidgetTester tester,
      String message, {
      FaixaErrorType? type,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FaixaErrorBanner(message: message, type: type),
          ),
        ),
      );
    }

    testWidgets('ícone de wifi para erro de rede', (tester) async {
      await pumpBanner(
        tester,
        'Sem conexao com a internet ou servidor indisponivel no momento.',
      );
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('ícone de cadeado para erro de autenticação', (tester) async {
      await pumpBanner(tester, 'Credenciais inválidas.');
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });

    testWidgets('ícone de alerta para erro de validação', (tester) async {
      await pumpBanner(tester, 'Informe um e-mail válido.');
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('ícone de erro para erro de servidor', (tester) async {
      await pumpBanner(tester, 'Erro interno. Tente novamente em instantes.');
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('tipo explícito sobrepõe a inferência', (tester) async {
      await pumpBanner(
        tester,
        'Erro interno. Tente novamente em instantes.',
        type: FaixaErrorType.network,
      );
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });
  });
}
