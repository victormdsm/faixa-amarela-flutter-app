import 'package:app_faixa_amarela/domain/models/child.dart';
import 'package:app_faixa_amarela/ui/core/widgets/child_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ChildSummaryCard displays child name', (tester) async {
    final child = Child(
      id: 1,
      name: 'Ana Silva',
      cpf: '12345678901',
      schoolId: 1,
      shiftId: 1,
      isInDebt: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChildSummaryCard(child: child)),
      ),
    );

    expect(find.text('Ana Silva'), findsOneWidget);
    expect(find.text('Dependente'), findsNothing);
  });

  testWidgets('ChildSummaryCard does not show CPF', (tester) async {
    final child = Child(
      id: 1,
      name: 'Ana Silva',
      cpf: '12345678901',
      schoolId: 1,
      shiftId: 1,
      isInDebt: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChildSummaryCard(child: child)),
      ),
    );

    expect(find.textContaining('12345678901'), findsNothing);
    expect(find.textContaining('123.456.789-01'), findsNothing);
  });

  testWidgets('ChildSummaryCard shows inadimplencia alert', (tester) async {
    final child = Child(
      id: 1,
      name: 'Ana Silva',
      cpf: '12345678901',
      schoolId: 1,
      shiftId: 1,
      isInDebt: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChildSummaryCard(child: child)),
      ),
    );

    expect(find.text('Inadimplente'), findsOneWidget);
  });
}
