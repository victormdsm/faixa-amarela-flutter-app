import 'package:app_faixa_amarela/features/auth/presentation/pages/activation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ActivationPage renders code input', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(home: const ActivationPage())),
    );

    expect(find.byType(TextField), findsAtLeastNWidgets(1));
    expect(find.text('Ativar conta'), findsAtLeastNWidgets(1));
  });
}
