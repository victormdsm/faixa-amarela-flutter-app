import 'package:app_faixa_amarela/core/presentation/widgets/faixa_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FaixaAppBar', () {
    testWidgets('portal renders brand logo and actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: FaixaAppBar.portal(
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.school_rounded), findsNothing);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('screen renders title and back button by default',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: FaixaAppBar.screen(title: 'Titulo da tela'),
          ),
        ),
      );

      expect(find.text('Titulo da tela'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });

    testWidgets('screen hides back button when showBack is false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: FaixaAppBar.screen(
              title: 'Sem voltar',
              showBack: false,
            ),
          ),
        ),
      );

      expect(find.text('Sem voltar'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    });
  });
}
