import 'package:app_faixa_amarela/app/router/app_router.dart';
import 'package:app_faixa_amarela/features/auth/presentation/pages/finalize_registration_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('FinalizeRegistrationPage renders input and has code button',
      (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.finalizeRegistration,
      routes: [
        GoRoute(
          path: AppRoutes.finalizeRegistration,
          builder: (context, state) => const FinalizeRegistrationPage(),
        ),
        GoRoute(
          path: AppRoutes.activation,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Activation Page')),
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

    await tester.drag(find.byType(Scaffold), const Offset(0, -200));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Já tenho um código'));
    await tester.pumpAndSettle();

    expect(find.text('Activation Page'), findsOneWidget);

    router.dispose();
  });
}
