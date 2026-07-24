// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_faixa_amarela/app/app.dart';

void main() {
  testWidgets('renderiza tela de login apos redesign', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FaixaAmarelaApp()));
    await tester.pumpAndSettle();

    // A nova tela de login (Stitch design) exibe o titulo do shell auth,
    // o botao de entrar e a acao anonima de busca de transporte.
    expect(find.text('Entrar no Faixa Amarela'), findsOneWidget);
    expect(find.text('Escolha seu perfil para continuar.'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Buscar transporte na minha região'), findsOneWidget);
  });
}
