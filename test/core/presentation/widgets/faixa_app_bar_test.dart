import 'package:app_faixa_amarela/core/presentation/widgets/faixa_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Router com um shell de duas abas — a mesma forma do portal do responsável
/// e do motorista — mais uma rota empilhada sobre ele.
GoRouter _buildRouter(GlobalKey<NavigatorState> rootKey) {
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/home',
    routes: [
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/empilhada',
        builder: (context, state) => Scaffold(
          appBar: FaixaAppBar.screen(title: 'Empilhada'),
          body: const SizedBox.shrink(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => Scaffold(body: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => Scaffold(
                  appBar: FaixaAppBar.portal(),
                  body: const Text('conteudo home'),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/aba-interna',
                builder: (context, state) => Scaffold(
                  appBar: FaixaAppBar.screen(title: 'Aba interna'),
                  body: const Text('conteudo aba'),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('FaixaAppBar.screen — voltar', () {
    testWidgets(
      'na raiz de uma aba do shell (nada empilhado) volta para a primeira aba',
      (tester) async {
        // Regressão: o voltar chamava maybePop(), que retorna false na raiz
        // de uma aba — o botão não executava nenhuma ação.
        final rootKey = GlobalKey<NavigatorState>();
        final router = _buildRouter(rootKey);
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        router.go('/aba-interna');
        await tester.pumpAndSettle();
        expect(find.text('conteudo aba'), findsOneWidget);

        await tester.tap(find.byTooltip('Voltar'));
        await tester.pumpAndSettle();

        expect(find.text('conteudo home'), findsOneWidget);
      },
    );

    testWidgets('com uma rota empilhada, desempilha normalmente', (
      tester,
    ) async {
      final rootKey = GlobalKey<NavigatorState>();
      final router = _buildRouter(rootKey);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      router.push('/empilhada');
      await tester.pumpAndSettle();
      expect(find.text('Empilhada'), findsOneWidget);

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      expect(find.text('Empilhada'), findsNothing);
      expect(find.text('conteudo home'), findsOneWidget);
    });

    testWidgets('onBack customizado tem precedência', (tester) async {
      var pressed = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: FaixaAppBar.screen(
              title: 'Custom',
              onBack: () => pressed++,
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pump();

      expect(pressed, 1);
    });
  });
}
