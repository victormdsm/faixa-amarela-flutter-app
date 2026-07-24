import 'package:app_faixa_amarela/core/presentation/widgets/faixa_section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FaixaSectionCard', () {
    testWidgets('renders title and child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FaixaSectionCard(
              title: 'Secao',
              child: Text('conteudo'),
            ),
          ),
        ),
      );

      expect(find.text('Secao'), findsOneWidget);
      expect(find.text('conteudo'), findsOneWidget);
    });

    testWidgets('renders icon and subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FaixaSectionCard(
              icon: Icons.info_outline,
              title: 'Secao',
              subtitle: 'Subtitulo',
              child: Text('conteudo'),
            ),
          ),
        ),
      );

      expect(find.text('Secao'), findsOneWidget);
      expect(find.text('Subtitulo'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('renders trailing widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FaixaSectionCard(
              title: 'Secao',
              trailing: TextButton(
                onPressed: () {},
                child: const Text('acao'),
              ),
              child: const Text('conteudo'),
            ),
          ),
        ),
      );

      expect(find.text('acao'), findsOneWidget);
    });
  });
}
