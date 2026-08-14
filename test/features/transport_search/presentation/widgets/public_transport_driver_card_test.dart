import 'package:app_faixa_amarela/app/theme/app_theme.dart';
import 'package:app_faixa_amarela/features/transport_search/domain/entities/public_transport_driver.dart';
import 'package:app_faixa_amarela/features/transport_search/presentation/widgets/public_transport_driver_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const driver = PublicTransportDriver(
    id: 1,
    name: 'José Motorista da Silva',
    cellPhone: '11999998888',
    information: 'Van amarela, porta lateral',
    avatarUrl: null,
    vehicleImageUrl: null,
    schools: ['Escola Municipal A', 'Escola Municipal B'],
    districts: ['Centro'],
    shiftIds: [1],
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    double textScale = 1.0,
    double width = 320,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: ListView(
              children: const [PublicTransportDriverCard(driver: driver)],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'card não quebra em largura apertada (320px)',
    (tester) async {
      await pumpCard(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Ver mais'), findsOneWidget);

      // Antes do fix, o FilledButton tinha largura mínima infinita (tema
      // global) e o Expanded do texto recebia largura 0 — o nome quebrava
      // um caractere por linha. Agora o nome precisa ter largura real.
      final nameWidth = tester
          .getSize(find.text('José Motorista da Silva'))
          .width;
      expect(nameWidth, greaterThan(20));

      // O botão continua visível com largura própria.
      final buttonWidth = tester.getSize(find.byType(FilledButton)).width;
      expect(buttonWidth, greaterThanOrEqualTo(88));
    },
  );

  testWidgets(
    'card não estoura com textScaler alto',
    (tester) async {
      // Nota: a fonte de teste (Ahem) tem glyphs ~2x mais largos que a fonte
      // real do app; 400px @ 1.3x equivale ao caso real de 320dp @ ~1.6x.
      await pumpCard(tester, textScale: 1.3, width: 400);

      expect(tester.takeException(), isNull);

      final nameWidth = tester
          .getSize(find.text('José Motorista da Silva'))
          .width;
      expect(nameWidth, greaterThan(40));

      final buttonWidth = tester.getSize(find.byType(FilledButton)).width;
      expect(buttonWidth, greaterThanOrEqualTo(88));
    },
  );

  testWidgets('botão Ver mais define largura mínima finita', (tester) async {
    await pumpCard(tester);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    final minSize = button.style?.minimumSize?.resolve({});
    expect(minSize, isNotNull);
    expect(minSize!.width.isFinite, isTrue);
    expect(minSize.width, 88);
  });
}
