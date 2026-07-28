import 'package:app_faixa_amarela/core/models/catalog_option.dart';
import 'package:app_faixa_amarela/core/presentation/widgets/e2e_keys.dart';
import 'package:app_faixa_amarela/domain/models/child.dart';
import 'package:app_faixa_amarela/features/catalog/data/catalog_repository.dart';
import 'package:app_faixa_amarela/features/parent_portal/presentation/pages/add_child_page.dart';
import 'package:app_faixa_amarela/features/parent_portal/presentation/providers/parent_portal_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_children_repository.dart';

void main() {
  const school = CatalogOption(id: 1, name: 'Escola A');
  const shift = CatalogOption(id: 2, name: 'Manhã');

  Widget buildPage({Child? childToEdit}) {
    return ProviderScope(
      overrides: [
        childrenRepositoryProvider.overrideWithValue(
          FakeChildrenRepository(),
        ),
        schoolsCatalogProvider.overrideWith((ref) async => [school]),
        shiftsCatalogProvider.overrideWith((ref) async => [shift]),
        citiesCatalogProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp(home: AddChildPage(childToEdit: childToEdit)),
    );
  }

  Finder documentField() => find.descendant(
    of: find.byKey(E2EKeys.childCpfInput),
    matching: find.byType(TextFormField),
  );

  /// UF do documento (RG) — distinta da UF do endereço, que usa o mesmo
  /// widget [UfSelectField].
  Finder documentUfField() => find.byKey(E2EKeys.childDocumentUfSelect);

  TextFormField documentWidget(WidgetTester tester) =>
      tester.widget<TextFormField>(documentField());

  /// Viewport alta para que a seção "Dados pessoais" inteira (seletor,
  /// documento, UF do RG) fique visível sem scroll.
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('default e CPF: sem campo de UF do RG', (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.text('CPF da criança'), findsOneWidget);
    expect(documentUfField(), findsNothing);
  });

  testWidgets('troca CPF→RG limpa o campo, exige UF; RG→CPF esconde a UF', (
    tester,
  ) async {
    useTallViewport(tester);
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await tester.enterText(documentField(), '12345678901');
    expect(documentWidget(tester).controller!.text, '12345678901');

    await tester.tap(find.text('RG'));
    await tester.pumpAndSettle();

    // Campo limpo + máscara/label de RG + UF obrigatória visível.
    expect(documentWidget(tester).controller!.text, isEmpty);
    expect(find.text('RG da criança'), findsOneWidget);
    expect(documentUfField(), findsOneWidget);

    // Validação exige número (5-14) e UF do RG.
    await tester.tap(find.text('Cadastrar dependente'));
    await tester.pumpAndSettle();
    expect(find.text('RG e obrigatorio.'), findsOneWidget);
    expect(find.text('Selecione a UF do RG.'), findsOneWidget);

    await tester.enterText(documentField(), '123');
    await tester.tap(find.text('Cadastrar dependente'));
    await tester.pumpAndSettle();
    expect(find.text('RG deve ter entre 5 e 14 caracteres.'), findsOneWidget);

    // Voltando para CPF: UF some e o campo volta limpo.
    await tester.tap(find.text('CPF'));
    await tester.pumpAndSettle();
    expect(documentUfField(), findsNothing);
    expect(find.text('CPF da criança'), findsOneWidget);
    expect(documentWidget(tester).controller!.text, isEmpty);
  });

  testWidgets('RG válido com UF não gera erros de documento', (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await tester.tap(find.text('RG'));
    await tester.pumpAndSettle();
    await tester.enterText(documentField(), '12.345.678-9');

    await tester.tap(documentUfField());
    await tester.pumpAndSettle();
    await tester.tap(find.text('PR').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cadastrar dependente'));
    await tester.pumpAndSettle();

    expect(find.text('RG e obrigatorio.'), findsNothing);
    expect(find.text('RG deve ter entre 5 e 14 caracteres.'), findsNothing);
    expect(find.text('Selecione a UF do RG.'), findsNothing);
    // Outros campos obrigatórios continuam barrando o envio.
    expect(find.text('Nome e obrigatorio.'), findsOneWidget);
  });

  testWidgets('edição carrega tipo RG e UF e mantém documento desabilitado', (
    tester,
  ) async {
    useTallViewport(tester);
    const child = Child(
      id: 5,
      name: 'Ana Silva',
      cpf: '12.345.678-9',
      documentType: ChildDocumentType.rg,
      documentState: 'PR',
      schoolId: 1,
      shiftId: 2,
    );

    await tester.pumpWidget(buildPage(childToEdit: child));
    await tester.pumpAndSettle();

    expect(find.text('RG da criança'), findsOneWidget);
    expect(documentWidget(tester).controller!.text, '12.345.678-9');
    expect(documentWidget(tester).enabled, isFalse);

    final ufField = tester.widget<DropdownButtonFormField<String>>(
      find.descendant(
        of: documentUfField(),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
    expect(ufField.initialValue, 'PR');

    // Documento imutável na edição: seletor desabilitado.
    final selector = tester.widget<SegmentedButton<String>>(
      find.byType(SegmentedButton<String>),
    );
    expect(selector.onSelectionChanged, isNull);
  });

  testWidgets('edição de criança legada (sem tipo) assume CPF', (
    tester,
  ) async {
    useTallViewport(tester);
    const child = Child(
      id: 5,
      name: 'Ana Silva',
      cpf: '12345678901',
      schoolId: 1,
      shiftId: 2,
    );

    await tester.pumpWidget(buildPage(childToEdit: child));
    await tester.pumpAndSettle();

    expect(find.text('CPF da criança'), findsOneWidget);
    expect(documentUfField(), findsNothing);
    expect(documentWidget(tester).controller!.text, '12345678901');
  });
}
