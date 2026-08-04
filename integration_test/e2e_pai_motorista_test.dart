import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app_faixa_amarela/app/app.dart';
import 'package:app_faixa_amarela/core/models/catalog_option.dart';
import 'package:app_faixa_amarela/core/presentation/widgets/e2e_keys.dart';
import 'package:app_faixa_amarela/features/auth/data/session_storage.dart';
import 'package:app_faixa_amarela/features/catalog/data/catalog_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';

/// Teste E2E real: pai cria dependente + endereco, motorista solicita matricula,
/// pai aceita matricula.
///
/// Roda com:
/// flutter test integration_test/e2e_pai_motorista_test.dart -d "iPhone 16e" --dart-define=API_BASE_URL=https://api.faixaamarela.com.br
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const parentEmail = 'xmastertutoriais@gmail.com';
  const driverEmail = 'aoextremogames@gmail.com';
  const password = 'Teste@1234';

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDownAll(() async {
    await _cleanupE2EChildren(parentEmail: parentEmail, password: password);
  });

  testWidgets('fluxo completo pai -> motorista -> pai', (tester) async {
    // Inicializa dependencias manualmente para o integration test.
    await Hive.initFlutter();
    await Future.wait([
      SessionStorage.openBox(),
      CatalogRepository.openCacheBox(),
    ]);
    await Firebase.initializeApp();

    final childName = 'E2E_TEST_${DateTime.now().millisecondsSinceEpoch}';
    final childCpf = _generateValidCpf();

    await tester.pumpWidget(const ProviderScope(child: FaixaAmarelaApp()));

    // Aguarda o app iniciar.
    await _waitFor(
      tester,
      () => find.byKey(E2EKeys.emailInput).evaluate().isNotEmpty ||
          find.byKey(E2EKeys.parentHome).evaluate().isNotEmpty ||
          find.byKey(E2EKeys.driverHome).evaluate().isNotEmpty,
      label: 'app iniciar',
      timeout: const Duration(seconds: 20),
    );
    await _logState(tester, 'inicio');

    // Garante que comeca na tela de login.
    if (find.byKey(E2EKeys.parentHome).evaluate().isNotEmpty ||
        find.byKey(E2EKeys.driverHome).evaluate().isNotEmpty) {
      await _logout(tester);
    }

    // -------------------------------------------------------------------------
    // 1. LOGIN COMO PAI
    // -------------------------------------------------------------------------
    await _login(
      tester,
      email: parentEmail,
      password: password,
      roleLabel: 'Pais',
      homeKey: E2EKeys.parentHome,
    );
    await _logState(tester, 'login pai ok');

    // -------------------------------------------------------------------------
    // 2. NAVEGAR PARA DEPENDENTES
    // -------------------------------------------------------------------------
    await _safeTap(tester, find.byKey(E2EKeys.parentChildrenAction));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Dependentes'), findsWidgets);
    await _logState(tester, 'tela dependentes');

    // -------------------------------------------------------------------------
    // 3. CRIAR CRIANCA + ENDERECO
    // -------------------------------------------------------------------------
    await _safeTap(tester, find.byKey(E2EKeys.childCreateButton));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Novo dependente'), findsOneWidget);
    await _logState(tester, 'tela novo dependente');

    await tester.enterText(find.byKey(E2EKeys.childNameInput), childName);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(E2EKeys.childCpfInput), childCpf);
    await tester.pumpAndSettle();

    await _selectDropdownByText(
      tester,
      E2EKeys.childSchoolDropdown,
      'Escola',
      'APAE Melvin Jones Unidade I',
    );
    await _selectDropdownByText(
      tester,
      E2EKeys.childShiftDropdown,
      'Turno',
      'Integral',
    );

    // Rola o formulario ate os campos de endereco ficarem renderizados.
    final formListView = find.byType(Scrollable).first;
    await tester.fling(formListView, const Offset(0, -400), 1000);
    await tester.pumpAndSettle();

    await _waitFor(
      tester,
      () => find.byKey(E2EKeys.addressStreetInput).evaluate().isNotEmpty,
      label: 'campo rua renderizado',
      timeout: const Duration(seconds: 5),
    );

    await tester.enterText(
      find.byKey(E2EKeys.addressStreetInput),
      'Rua E2E Teste',
    );
    await tester.enterText(find.byKey(E2EKeys.addressNumberInput), '123');
    await tester.enterText(
      find.byKey(E2EKeys.addressComplementInput),
      'Apto 1',
    );
    await tester.enterText(
      find.byKey(E2EKeys.addressZipCodeInput),
      '85851200',
    );
    await tester.pumpAndSettle();
    await _logState(tester, 'formulario preenchido');

    // Rola ate o botao de salvar ficar visivel (o teclado/dropdown pode te-lo
    // deslocado para fora da viewport). O ListView so renderiza o botao ao
    // scrollar para baixo.
    final listView = find.byType(Scrollable).first;
    await tester.fling(listView, const Offset(0, -300), 1000);
    await tester.pumpAndSettle();

    final saveButtonFinder = find.byKey(E2EKeys.childSaveButton);
    if (saveButtonFinder.evaluate().isEmpty) {
      throw Exception('Botao child_save_button nao encontrado na arvore');
    }
    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle(const Duration(seconds: 4));
    await _logState(tester, 'depois de salvar crianca');

    // A lista de dependentes usa ListView.builder; aguarda o nome aparecer.
    await _waitFor(
      tester,
      () =>
          find.text(childName).evaluate().isNotEmpty ||
          find.text('Joao Pacheco').evaluate().isNotEmpty ||
          find.text('Nenhum dependente encontrado.').evaluate().isNotEmpty ||
          find.text('Erro ao carregar dependentes.').evaluate().isNotEmpty,
      label: 'lista de dependentes carregar',
      timeout: const Duration(seconds: 15),
    );

    // O novo dependente pode ter sido inserido fora da viewport atual;
    // rola a lista ate encontra-lo.
    await tester.scrollUntilVisible(
      find.text(childName),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(childName), findsOneWidget);

    // O lookup do motorista agora e somente pelo codigo (UUID) da crianca;
    // busca o codigo via API (o pai ve o mesmo codigo no perfil da crianca).
    final childUuid = await _fetchChildUuid(
      parentEmail: parentEmail,
      password: password,
      childName: childName,
    );

    // -------------------------------------------------------------------------
    // 4. LOGOUT PAI
    // -------------------------------------------------------------------------
    // Volta para a home do pai (bottom nav "Inicio") para acessar o botao Sair.
    await _safeTap(tester, find.text('Inicio'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _logState(tester, 'voltou para home pai');

    await _logout(tester);
    await _logState(tester, 'logout pai ok');

    // -------------------------------------------------------------------------
    // 5. LOGIN COMO MOTORISTA
    // -------------------------------------------------------------------------
    await _login(
      tester,
      email: driverEmail,
      password: password,
      roleLabel: 'Tio da Van',
      homeKey: E2EKeys.driverHome,
    );
    await _logState(tester, 'login motorista ok');

    // -------------------------------------------------------------------------
    // 6. BUSCAR CRIANCA PELO CODIGO (UUID) E SOLICITAR MATRICULA
    // -------------------------------------------------------------------------
    await _safeTap(tester, find.byKey(E2EKeys.driverLookupButton));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Buscar crianca'), findsOneWidget);
    await _logState(tester, 'tela buscar crianca');

    await tester.enterText(find.byKey(E2EKeys.driverCpfInput), childUuid);
    await tester.pumpAndSettle();

    await _safeTap(tester, find.byKey(E2EKeys.driverSearchChildButton));
    await tester.pumpAndSettle(const Duration(seconds: 4));
    await _logState(tester, 'depois buscar crianca');

    expect(find.text(childName), findsOneWidget);

    // O card de resultado e scrollavel; garante que o botao de solicitacao
    // esteja visivel na viewport antes de tocar.
    await tester.scrollUntilVisible(
      find.byKey(E2EKeys.driverRequestEnrollmentButton),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(E2EKeys.driverRequestEnrollmentButton));
    await tester.pumpAndSettle();
    await _logState(tester, 'depois solicitar matricula');

    expect(
      find.text('Matricula solicitada com sucesso!'),
      findsOneWidget,
      reason: 'SnackBar de confirmacao nao apareceu',
    );
    // Aguarda o SnackBar desaparecer antes de prosseguir.
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // -------------------------------------------------------------------------
    // 7. LOGOUT MOTORISTA
    // -------------------------------------------------------------------------
    // A tela de busca foi aberta via push; volta para a home do motorista.
    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _logState(tester, 'voltou para home motorista');

    await _logout(tester);
    await _logState(tester, 'logout motorista ok');

    // -------------------------------------------------------------------------
    // 8. LOGIN PAI NOVAMENTE E ACEITAR MATRICULA
    // -------------------------------------------------------------------------
    await _login(
      tester,
      email: parentEmail,
      password: password,
      roleLabel: 'Pais',
      homeKey: E2EKeys.parentHome,
    );
    await _logState(tester, 'login pai novamente ok');

    await _safeTap(tester, find.text('Matriculas'));
    await tester.pumpAndSettle(const Duration(seconds: 4));
    await _logState(tester, 'tela matriculas');

    // A matricula da crianca recem-criada pode estar fora da viewport;
    // rola ate encontra-la.
    await tester.scrollUntilVisible(
      find.text(childName),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(childName), findsOneWidget);

    // Toca no botao "Aceitar" do card especifico da crianca.
    final childCard = find.ancestor(
      of: find.text(childName),
      matching: find.byType(Card),
    );
    final acceptButton = find.descendant(
      of: childCard,
      matching: find.byKey(E2EKeys.enrollmentAcceptButton),
    );
    await _safeTap(tester, acceptButton);
    await tester.pumpAndSettle(const Duration(seconds: 4));
    await _logState(tester, 'depois aceitar matricula');

    // A matricula da crianca atual deve desaparecer da lista de pendentes.
    // Outras matriculas de execucoes anteriores podem permanecer.
    await _waitFor(
      tester,
      () => find.text(childName).evaluate().isEmpty,
      label: 'matricula da crianca atual sumir da lista de pendentes',
      timeout: const Duration(seconds: 10),
    );
  });
}

Future<bool> _waitFor(
  WidgetTester tester,
  bool Function() condition, {
  required String label,
  required Duration timeout,
  bool throwOnTimeout = true,
}) async {
  final end = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      if (throwOnTimeout) {
        throw Exception('Timeout esperando por: $label');
      }
      return false;
    }
    await tester.pump(const Duration(milliseconds: 500));
  }
  await tester.pumpAndSettle();
  return true;
}

Future<void> _logState(WidgetTester tester, String label) async {
  // ignore: avoid_print
  print('[E2E] --- $label ---');
  final texts = find.byType(Text).evaluate().map((e) {
    final widget = e.widget as Text;
    return widget.data ?? '';
  }).where((t) => t.isNotEmpty).toList();
  // ignore: avoid_print
  print('[E2E] textos visiveis: ${texts.take(20).toList()}');
}

Future<void> _safeTap(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _selectDropdownByText(
  WidgetTester tester,
  Key dropdownKey,
  String label,
  String optionText,
) async {
  // Aguarda o catalogo carregar (sai do estado "Carregando...").
  await _waitFor(
    tester,
    () => find.descendant(
          of: find.byKey(dropdownKey),
          matching: find.text('Carregando...'),
        ).evaluate().isEmpty,
    label: 'catalogo $label carregar',
    timeout: const Duration(seconds: 10),
  );

  // Toca no DropdownButtonFormField interno para abrir o menu.
  final dropdownField = find.descendant(
    of: find.byKey(dropdownKey),
    matching: find.byType(DropdownButtonFormField<CatalogOption>),
  );
  expect(dropdownField, findsOneWidget,
      reason: 'Dropdown de $label nao encontrado');
  await tester.tap(dropdownField);
  await tester.pumpAndSettle();
  await _logState(tester, 'depois de abrir dropdown $label');

  // Aguarda o item de texto aparecer no overlay e toca nele.
  final optionFinder = find.text(optionText);
  await _waitFor(
    tester,
    () => optionFinder.evaluate().isNotEmpty,
    label: 'opcao "$optionText" do dropdown $label',
    timeout: const Duration(seconds: 5),
  );

  await tester.tap(optionFinder);
  await tester.pumpAndSettle();
}

Future<void> _login(
  WidgetTester tester, {
  required String email,
  required String password,
  required String roleLabel,
  required Key homeKey,
}) async {
  await _logState(tester, 'tentando login como $roleLabel');
  expect(find.byKey(E2EKeys.emailInput), findsOneWidget);

  final roleFinder = find.text(roleLabel);
  if (roleFinder.evaluate().isNotEmpty) {
    await tester.tap(roleFinder);
    await tester.pumpAndSettle();
  }

  await tester.enterText(find.byKey(E2EKeys.emailInput), email);
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(E2EKeys.passwordInput), password);
  await tester.pumpAndSettle();

  // Fecha o teclado para liberar a tela. No campo de senha, TextInputAction.done
  // dispara onSubmitted que executa o login, entao nao precisamos tap no botao.
  await tester.testTextInput.receiveAction(TextInputAction.done);

  // Aguarda a home aparecer (login via onSubmitted) ou da tap no botao como fallback.
  final foundHome = await _waitFor(
    tester,
    () => find.byKey(homeKey).evaluate().isNotEmpty,
    label: 'home de $roleLabel',
    timeout: const Duration(seconds: 10),
    throwOnTimeout: false,
  );

  if (!foundHome) {
    final loginButton = find.byKey(E2EKeys.loginButton);
    if (loginButton.evaluate().isNotEmpty) {
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }
  }

  expect(find.byKey(homeKey), findsOneWidget,
      reason: 'Home de $roleLabel nao apareceu apos login');
}

Future<void> _logout(WidgetTester tester) async {
  await _logState(tester, 'tentando logout');

  // O logout foi movido para as telas de perfil/configuracoes.
  // Navega ate o perfil via icone da AppBar e depois toca em "Sair".
  final profileFinder = find.byTooltip('Perfil');
  if (profileFinder.evaluate().isEmpty) {
    throw Exception('Nao encontrou botao de perfil na AppBar');
  }
  await tester.tap(profileFinder);
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Rola ate o botao Sair no final da tela de perfil.
  final scrollable = find.byType(Scrollable).last;
  await tester.scrollUntilVisible(
    find.widgetWithText(OutlinedButton, 'Sair'),
    200,
    scrollable: scrollable,
  );
  await tester.pumpAndSettle();

  final logoutButton = find.widgetWithText(OutlinedButton, 'Sair');
  if (logoutButton.evaluate().isEmpty) {
    throw Exception('Nao encontrou botao de logout na tela de perfil');
  }
  await tester.tap(logoutButton);
  await tester.pumpAndSettle();

  // Confirmar dialog, se houver.
  final confirmButton = find.widgetWithText(FilledButton, 'Sair');
  if (confirmButton.evaluate().isNotEmpty) {
    await tester.tap(confirmButton);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  expect(find.byKey(E2EKeys.emailInput), findsOneWidget,
      reason: 'Nao voltou para tela de login apos logout');
}

String _generateValidCpf() {
  final random = Random();
  final digits = List.generate(9, (_) => random.nextInt(10));

  int digit(List<int> base, int factor) {
    var sum = 0;
    for (var i = 0; i < base.length; i++) {
      sum += base[i] * (factor - i);
    }
    final result = (sum * 10) % 11;
    return result == 10 ? 0 : result;
  }

  final d1 = digit(digits, 10);
  final d2 = digit([...digits, d1], 11);

  return '${digits.join()}$d1$d2';
}

Future<String> _fetchChildUuid({
  required String parentEmail,
  required String password,
  required String childName,
}) async {
  const baseUrl = 'https://api.faixaamarela.com.br/api/v1';
  final client = HttpClient();
  try {
    final loginReq = await client.postUrl(
      Uri.parse('$baseUrl/auth/user/login'),
    );
    loginReq.headers.contentType = ContentType.json;
    loginReq.write(
      jsonEncode(<String, String>{'email': parentEmail, 'password': password}),
    );
    final loginRes = await loginReq.close();
    final loginBody = jsonDecode(
      await loginRes.transform(utf8.decoder).join(),
    ) as Map<String, dynamic>;
    final data = loginBody['data'] as Map<String, dynamic>?;
    final accessToken = data?['accessToken'] as String?;
    if (accessToken == null) {
      throw Exception('Login da API falhou ao buscar o codigo da crianca');
    }

    final listReq = await client.getUrl(
      Uri.parse('$baseUrl/parent/children'),
    );
    listReq.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    final listRes = await listReq.close();
    final listBody = jsonDecode(
      await listRes.transform(utf8.decoder).join(),
    ) as Map<String, dynamic>;
    final children =
        (listBody['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];

    for (final child in children) {
      if (child['name'] == childName) {
        final uuid = child['uuid'] as String?;
        if (uuid != null && uuid.isNotEmpty) return uuid;
      }
    }
    throw Exception('Crianca $childName sem codigo (uuid) na API');
  } finally {
    client.close();
  }
}

Future<void> _cleanupE2EChildren({
  required String parentEmail,
  required String password,
}) async {
  const baseUrl = 'https://api.faixaamarela.com.br/api/v1';
  final client = HttpClient();

  String? accessToken;
  try {
    final loginReq = await client.postUrl(
      Uri.parse('$baseUrl/auth/user/login'),
    );
    loginReq.headers.contentType = ContentType.json;
    loginReq.write(
      jsonEncode(<String, String>{'email': parentEmail, 'password': password}),
    );
    final loginRes = await loginReq.close();
    final loginBody = jsonDecode(
      await loginRes.transform(utf8.decoder).join(),
    ) as Map<String, dynamic>;
    final data = loginBody['data'] as Map<String, dynamic>?;
    accessToken = data?['accessToken'] as String?;
    if (accessToken == null) return;

    final listReq = await client.getUrl(
      Uri.parse('$baseUrl/parent/children'),
    );
    listReq.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    final listRes = await listReq.close();
    final listBody = jsonDecode(
      await listRes.transform(utf8.decoder).join(),
    ) as Map<String, dynamic>;
    final children = (listBody['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    for (final child in children) {
      final name = (child['name'] as String? ?? '');
      if (name.startsWith('E2E_TEST_')) {
        final id = child['id'].toString();
        final deleteReq = await client.deleteUrl(
          Uri.parse('$baseUrl/parent/children/$id'),
        );
        deleteReq.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $accessToken',
        );
        await deleteReq.close();
      }
    }
  } finally {
    client.close();
  }
}
