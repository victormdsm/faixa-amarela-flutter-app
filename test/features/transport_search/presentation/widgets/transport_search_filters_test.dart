import 'package:app_faixa_amarela/app/theme/app_theme.dart';
import 'package:app_faixa_amarela/core/presentation/widgets/faixa_searchable_single_select.dart';
import 'package:app_faixa_amarela/features/transport_search/domain/entities/public_transport_driver.dart';
import 'package:app_faixa_amarela/features/transport_search/domain/entities/service_period.dart';
import 'package:app_faixa_amarela/features/transport_search/presentation/state/transport_search_filters_state.dart';
import 'package:app_faixa_amarela/features/transport_search/presentation/widgets/transport_search_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const schools = <String>['APAE Centro', 'Escola Municipal A'];
  const neighborhoods = <String>['Centro', 'São João'];

  Future<void> pumpFilters(
    WidgetTester tester, {
    required TransportSearchFiltersState filters,
    required ValueChanged<String?> onSchoolSelected,
    required ValueChanged<String?> onNeighborhoodSelected,
    required ValueChanged<ServicePeriod?> onPeriodChanged,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: TransportSearchFilters(
              filters: filters,
              schools: schools,
              neighborhoods: neighborhoods,
              driversAsync: const AsyncValue.data([]),
              filteredCount: 0,
              onSchoolSelected: onSchoolSelected,
              onNeighborhoodSelected: onNeighborhoodSelected,
              onPeriodChanged: onPeriodChanged,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renderiza os campos de escola e bairro', (tester) async {
    await pumpFilters(
      tester,
      filters: const TransportSearchFiltersState(),
      onSchoolSelected: (_) {},
      onNeighborhoodSelected: (_) {},
      onPeriodChanged: (_) {},
    );

    expect(find.text('Escola'), findsOneWidget);
    expect(find.text('Bairro'), findsOneWidget);
    expect(find.byType(FaixaSearchableSingleSelect), findsNWidgets(2));
  });

  testWidgets('selecionar escola chama onSchoolSelected com o nome', (
    tester,
  ) async {
    String? selectedSchool;
    await pumpFilters(
      tester,
      filters: const TransportSearchFiltersState(),
      onSchoolSelected: (value) => selectedSchool = value,
      onNeighborhoodSelected: (_) {},
      onPeriodChanged: (_) {},
    );

    // O primeiro seletor é a escola.
    await tester.tap(find.byType(FaixaSearchableSingleSelect).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('APAE Centro'));
    await tester.pumpAndSettle();

    expect(selectedSchool, 'APAE Centro');
  });

  testWidgets('selecionar bairro chama onNeighborhoodSelected com o nome', (
    tester,
  ) async {
    String? selectedNeighborhood;
    await pumpFilters(
      tester,
      filters: const TransportSearchFiltersState(),
      onSchoolSelected: (_) {},
      onNeighborhoodSelected: (value) => selectedNeighborhood = value,
      onPeriodChanged: (_) {},
    );

    // O segundo seletor é o bairro.
    await tester.tap(find.byType(FaixaSearchableSingleSelect).at(1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('São João'));
    await tester.pumpAndSettle();

    expect(selectedNeighborhood, 'São João');
  });

  testWidgets('limpar escola chama onSchoolSelected com null', (tester) async {
    String? selectedSchool = 'não deve mudar';
    await pumpFilters(
      tester,
      filters: const TransportSearchFiltersState(
        school: 'APAE Centro',
      ),
      onSchoolSelected: (value) => selectedSchool = value,
      onNeighborhoodSelected: (_) {},
      onPeriodChanged: (_) {},
    );

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();

    expect(selectedSchool, isNull);
  });

  testWidgets('lista vazia de escolas exibe emptyResultsText', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: TransportSearchFilters(
              filters: const TransportSearchFiltersState(),
              schools: const <String>[],
              neighborhoods: neighborhoods,
              driversAsync: const AsyncValue.data([]),
              filteredCount: 0,
              onSchoolSelected: (_) {},
              onNeighborhoodSelected: (_) {},
              onPeriodChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FaixaSearchableSingleSelect).first);
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma escola carregada da API.'), findsOneWidget);
  });
}
