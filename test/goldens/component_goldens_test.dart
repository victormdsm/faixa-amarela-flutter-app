import 'package:app_faixa_amarela/core/presentation/widgets/faixa_section_card.dart';
import 'package:app_faixa_amarela/domain/models/child.dart';
import 'package:app_faixa_amarela/features/auth/presentation/pages/activation_page.dart';
import 'package:app_faixa_amarela/features/auth/presentation/pages/login_page.dart';
import 'package:app_faixa_amarela/ui/core/widgets/child_summary_card.dart';
import 'package:app_faixa_amarela/ui/core/widgets/status_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A logo do header (AuthShell) decodifica de forma assíncrona; sem o
  // precache o primeiro golden que a usa renderiza sem a imagem.
  Future<void> precacheLogo(WidgetTester tester) async {
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/logo_lockup.png'),
        tester.binding.rootElement!,
      );
    });
  }

  testWidgets('ChildSummaryCard golden', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChildSummaryCard(
            child: Child(
              id: 1,
              name: 'Ana Silva',
              cpf: '12345678901',
              schoolId: 1,
              shiftId: 1,
              isInDebt: false,
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(ChildSummaryCard),
      matchesGoldenFile('goldens/child_summary_card.png'),
    );
  });

  testWidgets('StatusPill golden', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusPill(label: 'Pendente', color: Colors.orange),
        ),
      ),
    );
    await expectLater(
      find.byType(StatusPill),
      matchesGoldenFile('goldens/status_pill.png'),
    );
  });

  testWidgets('LoginPage golden', (tester) async {
    await precacheLogo(tester);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(LoginPage),
      matchesGoldenFile('goldens/login_page.png'),
    );
  });

  testWidgets('ActivationPage golden', (tester) async {
    await precacheLogo(tester);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ActivationPage())),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ActivationPage),
      matchesGoldenFile('goldens/activation_page.png'),
    );
  });

  testWidgets('FaixaSectionCard golden', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: FaixaSectionCard(
              icon: Icons.person_outline,
              title: 'Dados pessoais',
              subtitle: 'Preencha as informacoes abaixo.',
              child: Text('Conteudo do card'),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(FaixaSectionCard),
      matchesGoldenFile('goldens/faixa_section_card.png'),
    );
  });
}
