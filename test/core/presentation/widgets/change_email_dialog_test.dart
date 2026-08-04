import 'package:app_faixa_amarela/core/presentation/widgets/change_email_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<EmailChangeResult?> pumpDialog(
    WidgetTester tester, {
    required WidgetTesterCallback interact,
  }) async {
    EmailChangeResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await showDialog<EmailChangeResult>(
                context: context,
                builder: (_) => const ChangeEmailDialog(),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await interact(tester);
    return result;
  }

  group('ChangeEmailDialog', () {
    testWidgets('exige o novo e-mail', (tester) async {
      await pumpDialog(
        tester,
        interact: (tester) async {
          await tester.tap(find.text('Salvar'));
          await tester.pumpAndSettle();
        },
      );

      expect(find.text('Informe o novo e-mail.'), findsOneWidget);
    });

    testWidgets('exige um e-mail válido', (tester) async {
      await pumpDialog(
        tester,
        interact: (tester) async {
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Novo e-mail'),
            'nao-eh-email',
          );
          await tester.tap(find.text('Salvar'));
          await tester.pumpAndSettle();
        },
      );

      expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    });

    testWidgets('exige a senha atual', (tester) async {
      await pumpDialog(
        tester,
        interact: (tester) async {
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Novo e-mail'),
            'novo@exemplo.com',
          );
          await tester.tap(find.text('Salvar'));
          await tester.pumpAndSettle();
        },
      );

      expect(find.text('Informe a senha atual.'), findsOneWidget);
    });

    testWidgets('retorna EmailChangeResult quando tudo é válido', (
      tester,
    ) async {
      final result = await pumpDialog(
        tester,
        interact: (tester) async {
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Novo e-mail'),
            'novo@exemplo.com',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Senha atual'),
            'senha-atual-123',
          );
          await tester.tap(find.text('Salvar'));
          await tester.pumpAndSettle();
        },
      );

      expect(result, isNotNull);
      expect(result!.newEmail, 'novo@exemplo.com');
      expect(result.currentPassword, 'senha-atual-123');
    });

    testWidgets('cancelar fecha sem resultado', (tester) async {
      final result = await pumpDialog(
        tester,
        interact: (tester) async {
          await tester.tap(find.text('Cancelar'));
          await tester.pumpAndSettle();
        },
      );

      expect(result, isNull);
    });
  });
}
