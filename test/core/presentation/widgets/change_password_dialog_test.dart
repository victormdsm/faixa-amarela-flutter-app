import 'package:app_faixa_amarela/core/presentation/widgets/change_password_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<PasswordResult?> pumpDialog(
    WidgetTester tester, {
    required WidgetTesterCallback interact,
  }) async {
    PasswordResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await showDialog<PasswordResult>(
                context: context,
                builder: (_) => const ChangePasswordDialog(),
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

  group('ChangePasswordDialog (APP-05)', () {
    testWidgets('exige a senha atual', (tester) async {
      await pumpDialog(
        tester,
        interact: (tester) async {
          await tester.tap(find.text('Salvar'));
          await tester.pumpAndSettle();
        },
      );

      expect(find.text('Informe a senha atual.'), findsOneWidget);
    });

    testWidgets('exige nova senha com ao menos 6 caracteres', (tester) async {
      await pumpDialog(
        tester,
        interact: (tester) async {
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Senha atual'),
            'atual-123',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Nova senha'),
            '123',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Confirmar nova senha'),
            '123',
          );
          await tester.tap(find.text('Salvar'));
          await tester.pumpAndSettle();
        },
      );

      expect(
        find.text('A senha deve ter pelo menos 6 caracteres.'),
        findsOneWidget,
      );
    });

    testWidgets('exige confirmação igual à nova senha', (tester) async {
      await pumpDialog(
        tester,
        interact: (tester) async {
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Senha atual'),
            'atual-123',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Nova senha'),
            'nova-senha-1',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Confirmar nova senha'),
            'outra-coisa',
          );
          await tester.tap(find.text('Salvar'));
          await tester.pumpAndSettle();
        },
      );

      expect(find.text('As senhas não coincidem.'), findsOneWidget);
    });

    testWidgets('retorna PasswordResult quando tudo é válido', (tester) async {
      final result = await pumpDialog(
        tester,
        interact: (tester) async {
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Senha atual'),
            'atual-123',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Nova senha'),
            'nova-senha-1',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Confirmar nova senha'),
            'nova-senha-1',
          );
          await tester.tap(find.text('Salvar'));
          await tester.pumpAndSettle();
        },
      );

      expect(result, isNotNull);
      expect(result!.currentPassword, 'atual-123');
      expect(result.newPassword, 'nova-senha-1');
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
