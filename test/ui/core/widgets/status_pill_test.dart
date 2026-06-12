import 'package:app_faixa_amarela/ui/core/widgets/status_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StatusPill displays label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusPill(label: 'Pendente', color: Colors.orange),
        ),
      ),
    );

    expect(find.text('Pendente'), findsOneWidget);
  });
}
