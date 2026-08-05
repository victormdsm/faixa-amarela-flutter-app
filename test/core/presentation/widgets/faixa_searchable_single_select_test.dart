import 'package:app_faixa_amarela/app/theme/app_theme.dart';
import 'package:app_faixa_amarela/core/presentation/widgets/faixa_searchable_single_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const options = <String>[
    'APAE Centro',
    'APAE Norte',
    'Escola Municipal A',
    'São João Bairro',
  ];

  Future<void> pumpWidget(
    WidgetTester tester, {
    String? value,
    required ValueChanged<String?> onSelected,
    VoidCallback? onCleared,
    List<String> options = options,
    String? emptyResultsText,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: FaixaSearchableSingleSelect(
            label: 'Escola',
            hintText: 'Selecione a escola',
            title: 'Selecione a escola',
            searchHint: 'Buscar escola',
            options: options,
            value: value,
            onSelected: onSelected,
            onCleared: onCleared,
            emptyResultsText: emptyResultsText,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byType(FaixaSearchableSingleSelect));
    await tester.pumpAndSettle();
  }

  Finder searchField() =>
      find.byKey(const ValueKey('faixa_searchable_single_select_search_field'));

  testWidgets('exibe label e hint quando não há valor selecionado', (
    tester,
  ) async {
    await pumpWidget(
      tester,
      onSelected: (_) {},
    );

    expect(find.text('Escola'), findsOneWidget);
    expect(find.text('Selecione a escola'), findsOneWidget);
  });

  testWidgets('exibe valor selecionado no campo', (tester) async {
    await pumpWidget(
      tester,
      value: 'APAE Centro',
      onSelected: (_) {},
    );

    expect(find.text('APAE Centro'), findsOneWidget);
  });

  testWidgets('abre bottom sheet com todas as opções', (tester) async {
    await pumpWidget(
      tester,
      onSelected: (_) {},
    );

    await openSheet(tester);

    for (final option in options) {
      expect(find.text(option), findsOneWidget);
    }
  });

  testWidgets('campo de busca filtra a lista em tempo real', (tester) async {
    String? selected;
    await pumpWidget(
      tester,
      onSelected: (value) => selected = value,
    );

    await openSheet(tester);

    await tester.enterText(searchField(), 'APAE');
    await tester.pumpAndSettle();

    expect(find.text('APAE Centro'), findsOneWidget);
    expect(find.text('APAE Norte'), findsOneWidget);
    expect(find.text('Escola Municipal A'), findsNothing);
  });

  testWidgets('filtro é case-insensitive', (tester) async {
    await pumpWidget(
      tester,
      onSelected: (_) {},
    );

    await openSheet(tester);

    await tester.enterText(searchField(), 'apae');
    await tester.pumpAndSettle();

    expect(find.text('APAE Centro'), findsOneWidget);
    expect(find.text('APAE Norte'), findsOneWidget);
  });

  testWidgets('filtro ignora acentos', (tester) async {
    await pumpWidget(
      tester,
      onSelected: (_) {},
    );

    await openSheet(tester);

    await tester.enterText(searchField(), 'sao joao');
    await tester.pumpAndSettle();

    expect(find.text('São João Bairro'), findsOneWidget);
    expect(find.text('APAE Centro'), findsNothing);
  });

  testWidgets('tocar em um item seleciona e chama onSelected com o nome', (
    tester,
  ) async {
    String? selected;
    await pumpWidget(
      tester,
      onSelected: (value) => selected = value,
    );

    await openSheet(tester);

    await tester.tap(find.text('Escola Municipal A'));
    await tester.pumpAndSettle();

    expect(selected, 'Escola Municipal A');
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('ícone de limpar no campo chama onCleared', (tester) async {
    var cleared = false;
    await pumpWidget(
      tester,
      value: 'APAE Centro',
      onSelected: (_) {},
      onCleared: () => cleared = true,
    );

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(cleared, isTrue);
  });

  testWidgets('botão Limpar no sheet chama onCleared', (tester) async {
    var cleared = false;
    await pumpWidget(
      tester,
      value: 'APAE Centro',
      onSelected: (_) {},
      onCleared: () => cleared = true,
    );

    await openSheet(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Limpar'));
    await tester.pumpAndSettle();

    expect(cleared, isTrue);
  });

  testWidgets('lista vazia exibe emptyResultsText', (tester) async {
    await pumpWidget(
      tester,
      options: const <String>[],
      onSelected: (_) {},
      emptyResultsText: 'Nenhuma escola carregada da API.',
    );

    await openSheet(tester);

    expect(find.text('Nenhuma escola carregada da API.'), findsOneWidget);
  });

  testWidgets('busca sem resultados exibe mensagem padrão', (tester) async {
    await pumpWidget(
      tester,
      onSelected: (_) {},
    );

    await openSheet(tester);

    await tester.enterText(searchField(), 'xyz123');
    await tester.pumpAndSettle();

    expect(find.text('Nenhum resultado encontrado.'), findsOneWidget);
  });

  testWidgets('fechar o sheet sem selecionar não chama onSelected', (
    tester,
  ) async {
    String? selected = 'não deve mudar';
    await pumpWidget(
      tester,
      onSelected: (value) => selected = value,
    );

    await openSheet(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Fechar'));
    await tester.pumpAndSettle();

    expect(selected, 'não deve mudar');
  });
}
