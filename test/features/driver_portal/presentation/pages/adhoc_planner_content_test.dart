import 'package:app_faixa_amarela/app/theme/app_theme.dart';
import 'package:app_faixa_amarela/domain/repositories/routes_repository.dart';
import 'package:app_faixa_amarela/features/driver_portal/presentation/pages/driver_routes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRoutesRepository extends Mock implements RoutesRepository {}

const _ana = PlanningChild(
  id: 1,
  name: 'Ana Silva',
  schoolId: 10,
  schoolName: 'Escola Alfa',
  address: 'Rua A, 100',
  selectedByDefault: false,
);

const _bruno = PlanningChild(
  id: 2,
  name: 'Bruno Souza',
  schoolId: 10,
  schoolName: 'Escola Alfa',
  address: 'Rua B, 200',
);

const _carla = PlanningChild(
  id: 3,
  name: 'Carla Lima',
  schoolId: 20,
  schoolName: 'Escola Beta',
  address: 'Rua C, 300',
);

void main() {
  late MockRoutesRepository repo;

  setUp(() {
    repo = MockRoutesRepository();
    when(
      () => repo.getPlanningOptions(
        shiftId: any(named: 'shiftId'),
        period: any(named: 'period'),
      ),
    ).thenAnswer(
      (_) async => const RoutePlanningOptions(
        vans: [],
        children: [_ana, _bruno, _carla],
      ),
    );
  });

  Future<void> pumpPlanner(
    WidgetTester tester, {
    Future<void> Function(String? period, List<int>? childIds)? onStart,
  }) async {
    // Viewport alta para que todos os cards da lista sejam construídos.
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    body: AdhocPlannerContent(
                      repo: repo,
                      onStart: onStart ?? (_, _) async {},
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  List<Checkbox> checkboxes(WidgetTester tester) {
    return tester
        .widgetList<Checkbox>(find.byType(Checkbox))
        .toList(growable: false);
  }

  testWidgets('checkbox inicial segue selectedByDefault do backend', (
    tester,
  ) async {
    await pumpPlanner(tester);

    final boxes = checkboxes(tester);
    expect(boxes, hasLength(3));
    // Integral em manhã_volta: aparece na lista mas começa desmarcada.
    expect(boxes[0].value, isFalse);
    expect(boxes[1].value, isTrue);
    expect(boxes[2].value, isTrue);
    expect(find.text('2 de 3 dependentes na rota'), findsOneWidget);
  });

  testWidgets('lista renderiza cabeçalho de escola ao mudar de escola', (
    tester,
  ) async {
    await pumpPlanner(tester);

    // Backend ordena por escola + nome; cada escola aparece uma única vez
    // como cabeçalho de grupo, antes dos seus alunos.
    expect(find.text('Escola Alfa'), findsOneWidget);
    expect(find.text('Escola Beta'), findsOneWidget);

    final alfaDy = tester.getTopLeft(find.text('Escola Alfa')).dy;
    final anaDy = tester.getTopLeft(find.text('Ana Silva')).dy;
    final betaDy = tester.getTopLeft(find.text('Escola Beta')).dy;
    final carlaDy = tester.getTopLeft(find.text('Carla Lima')).dy;
    expect(alfaDy, lessThan(anaDy));
    expect(betaDy, lessThan(carlaDy));
    expect(anaDy, lessThan(betaDy));
  });

  testWidgets('seletor de período inclui Noite Volta', (tester) async {
    await pumpPlanner(tester);

    expect(find.text('Noite Volta'), findsOneWidget);
    expect(find.text('Noite Ida'), findsOneWidget);
  });

  testWidgets('seleção completa inicia rota sem childIds (compat)', (
    tester,
  ) async {
    // Todas selecionadas por padrão: re-marco a Ana para completar a lista.
    List<int>? capturedChildIds;
    var called = false;
    await pumpPlanner(
      tester,
      onStart: (period, childIds) async {
        called = true;
        capturedChildIds = childIds;
      },
    );

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar rota'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(capturedChildIds, isNull);
  });

  testWidgets('desmarcar criança envia childIds com o subconjunto e o período',
      (tester) async {
    List<int>? capturedChildIds;
    String? capturedPeriod;
    var sentinel = <int>[-1];
    capturedChildIds = sentinel;
    await pumpPlanner(
      tester,
      onStart: (period, childIds) async {
        capturedPeriod = period;
        capturedChildIds = childIds;
      },
    );

    await tester.tap(find.text('Noite Volta'));
    await tester.pumpAndSettle();

    // Desmarca Bruno (id 2): Ana já vinha desmarcada por selectedByDefault.
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();
    expect(find.text('1 de 3 dependentes na rota'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar rota'));
    await tester.pumpAndSettle();

    expect(capturedPeriod, 'noite_volta');
    expect(capturedChildIds, isNot(equals(sentinel)));
    expect(capturedChildIds, [3]);
  });

  testWidgets('desmarcar todas desabilita o botão Iniciar rota', (
    tester,
  ) async {
    await pumpPlanner(tester);

    // Desmarca Bruno e Carla (Ana já começa desmarcada).
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.tap(find.byType(Checkbox).at(2));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Iniciar rota'),
    );
    expect(button.onPressed, isNull);
    expect(find.text('0 de 3 dependentes na rota'), findsOneWidget);
  });
}
