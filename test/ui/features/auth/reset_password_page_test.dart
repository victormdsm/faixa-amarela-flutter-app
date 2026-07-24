import 'package:app_faixa_amarela/app/router/app_router.dart';
import 'package:app_faixa_amarela/features/auth/presentation/pages/reset_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('ResetPasswordPage renders token and password fields',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: const ResetPasswordPage(),
        ),
      ),
    );

    expect(find.byType(TextField), findsAtLeastNWidgets(2));
    expect(find.text('Redefinir senha'), findsAtLeastNWidgets(1));
  });

  testWidgets('ResetPasswordPage prefills token from query parameter',
      (tester) async {
    final router = GoRouter(
      initialLocation: '${AppRoutes.resetPassword}?token=ABC123',
      routes: [
        GoRoute(
          path: AppRoutes.resetPassword,
          builder: (context, state) => const ResetPasswordPage(),
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

    final tokenField = tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.labelText == 'Código de recuperação',
      ),
    );

    expect(
      (tokenField.controller ?? TextEditingController()).text,
      'ABC123',
    );

    router.dispose();
  });
}
