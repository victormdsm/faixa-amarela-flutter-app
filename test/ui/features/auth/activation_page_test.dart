import 'package:app_faixa_amarela/app/router/app_router.dart';
import 'package:app_faixa_amarela/features/auth/presentation/pages/activation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('ActivationPage renders code input', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(home: const ActivationPage())),
    );

    expect(find.byType(TextField), findsAtLeastNWidgets(1));
    expect(find.text('Ativar conta'), findsAtLeastNWidgets(1));
  });

  testWidgets('ActivationPage prefills code and email from query parameters',
      (tester) async {
    final router = GoRouter(
      initialLocation: '${AppRoutes.activation}?token=123456&email=user@email.com',
      routes: [
        GoRoute(
          path: AppRoutes.activation,
          builder: (context, state) => const ActivationPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final textFields = tester.widgetList<TextField>(find.byType(TextField));
    final emailField = textFields.firstWhere(
      (field) => field.decoration?.labelText == 'E-mail ou CPF',
    );
    final codeField = textFields.firstWhere(
      (field) => field.decoration?.labelText == 'Código de ativação',
    );

    expect(
      (emailField.controller ?? TextEditingController()).text,
      'user@email.com',
    );
    expect(
      (codeField.controller ?? TextEditingController()).text,
      '123456',
    );

    router.dispose();
  });
}
