import 'package:app_faixa_amarela/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LoginPage renders email and password fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );

    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsAtLeastNWidgets(2));
    expect(find.text('Entrar'), findsAtLeastNWidgets(1));
  });

  testWidgets('LoginPage shows role selector', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pais'), findsOneWidget);
    expect(find.text('Tio da Van'), findsOneWidget);
  });
}
