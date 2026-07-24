import 'package:app_faixa_amarela/app/router/app_router.dart';
import 'package:app_faixa_amarela/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('ForgotPasswordPage renders email input and has code button',
      (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.forgotPassword,
      routes: [
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (context, state) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: AppRoutes.resetPassword,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Reset Password Page')),
          ),
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

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Já tenho um código'), findsOneWidget);

    await tester.tap(find.text('Já tenho um código'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Password Page'), findsOneWidget);

    router.dispose();
  });
}
