import 'package:app_faixa_amarela/features/parent_portal/presentation/widgets/live_tracking_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveTrackingOverlay — indicador de conexão em tempo real', () {
    Future<void> pumpOverlay(
      WidgetTester tester, {
      required bool isLive,
      bool connectionIssue = false,
      VoidCallback? onRetry,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTrackingOverlay(
              dependents: const [],
              isLive: isLive,
              connectionIssue: connectionIssue,
              onRetry: onRetry,
            ),
          ),
        ),
      );
    }

    testWidgets('conectado: pill discreta "Ao vivo" em verde', (tester) async {
      await pumpOverlay(tester, isLive: true);

      expect(find.text('Ao vivo'), findsOneWidget);
      expect(find.text('Atualizando…'), findsNothing);
      expect(find.text('Tentar de novo'), findsNothing);
      expect(find.textContaining('Sem conexão'), findsNothing);
    });

    testWidgets('queda transitória: pill neutra "Atualizando…", sem alarme', (
      tester,
    ) async {
      await pumpOverlay(tester, isLive: false);

      expect(find.text('Atualizando…'), findsOneWidget);
      expect(find.text('Ao vivo'), findsNothing);
      expect(find.text('Tentar de novo'), findsNothing);
      expect(find.textContaining('Sem conexão'), findsNothing);
    });

    testWidgets(
      'falha persistente: mensagem clara do fallback de 15s + tentar de novo',
      (tester) async {
        var retried = false;
        await pumpOverlay(
          tester,
          isLive: false,
          connectionIssue: true,
          onRetry: () => retried = true,
        );

        expect(
          find.text(
            'Sem conexão em tempo real — os dados atualizam a cada 15s.',
          ),
          findsOneWidget,
        );
        expect(find.text('Atualizando…'), findsNothing);
        expect(find.text('Ao vivo'), findsNothing);

        await tester.tap(find.text('Tentar de novo'));
        await tester.pump();
        expect(retried, isTrue);
      },
    );

    testWidgets('a palavra "reconectando" não aparece em nenhum estado', (
      tester,
    ) async {
      for (final isLive in [true, false]) {
        for (final issue in [true, false]) {
          await pumpOverlay(
            tester,
            isLive: isLive,
            connectionIssue: issue,
            onRetry: () {},
          );
          expect(
            find.textContaining('econectand'),
            findsNothing,
            reason: 'isLive=$isLive, connectionIssue=$issue',
          );
        }
      }
    });
  });
}
