import 'package:app_faixa_amarela/core/presentation/widgets/faixa_profile_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FaixaProfileHero', () {
    testWidgets('renders name and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FaixaProfileHero(
              name: 'Joao Silva',
              subtitle: 'Responsavel',
            ),
          ),
        ),
      );

      expect(find.text('Joao Silva'), findsOneWidget);
      expect(find.text('Responsavel'), findsOneWidget);
    });

    testWidgets('renders fallback when name is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FaixaProfileHero(name: ''),
          ),
        ),
      );

      expect(find.text('Usuario'), findsOneWidget);
    });

    testWidgets('renders tag when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FaixaProfileHero(
              name: 'Maria',
              tag: 'Motorista',
            ),
          ),
        ),
      );

      expect(find.text('Motorista'), findsOneWidget);
    });

    testWidgets('camera icon appears when onAvatarTap is provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FaixaProfileHero(
              name: 'Maria',
              onAvatarTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    });
  });
}
