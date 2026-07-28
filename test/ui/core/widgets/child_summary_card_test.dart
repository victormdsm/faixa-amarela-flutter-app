import 'package:app_faixa_amarela/app/theme/app_theme.dart';
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

  testWidgets(
    'ChildSummaryCard com ações não estoura em tela estreita com o tema do app',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

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
          theme: AppTheme.light(),
          home: Scaffold(
            body: ChildSummaryCard(
              child: child,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // O FilledButton "Editar" fica num Row não-flex; com o tema global
      // (largura mínima infinita) ele overflow sem o style local.
      expect(tester.takeException(), isNull);
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Excluir'), findsOneWidget);
    },
  );
}
