import 'package:app_faixa_amarela/app/theme/app_theme.dart';
import 'package:app_faixa_amarela/features/transport_search/domain/entities/public_transport_driver.dart';
import 'package:app_faixa_amarela/features/transport_search/presentation/providers/transport_search_providers.dart';
import 'package:app_faixa_amarela/features/transport_search/presentation/widgets/public_transport_driver_card.dart';
import 'package:app_faixa_amarela/features/transport_search/presentation/widgets/public_transport_driver_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const driver = PublicTransportDriver(
    id: 7,
    name: 'José Motorista da Silva',
    cellPhone: '11999998888',
    information: 'Van com cadeirinha e monitora inclusa.',
    avatarUrl: null,
    vehicleImageUrl: null,
    districts: ['Centro'],
    publicContactName: 'Tio Zé',
    publicContactPhone: '11988887777',
    vehicleDescription: 'Fiat Ducato • Branca • 2020',
  );

  Widget app(Widget child, {List<PublicTransportDriver>? searchResults}) {
    return ProviderScope(
      overrides: [
        transportDriversProvider.overrideWith(
          (ref) async => searchResults ?? [driver],
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    );
  }

  group('PublicTransportDriver.fromJson', () {
    test('faz o parse do contrato público enxuto', () {
      final parsed = PublicTransportDriver.fromJson(const {
        'id': 7,
        'name': 'Tio Zé',
        'phone': '11988887777',
        'information': 'Van com cadeirinha.',
        'publicContactName': 'Tio Zé',
        'publicContactPhone': '11988887777',
        'vehicleDescription': 'Fiat Ducato • Branca • 2020',
        'districts': ['Centro'],
      });

      expect(parsed.information, 'Van com cadeirinha.');
      expect(parsed.about, 'Van com cadeirinha.');
      expect(parsed.publicContactPhone, '11988887777');
      expect(parsed.vehicleDescription, 'Fiat Ducato • Branca • 2020');
      expect(parsed.districts, ['Centro']);
      expect(parsed.contactPhone, '11988887777');
    });

    test('ignora escolas, turnos e cnh de um payload legado', () {
      final parsed = PublicTransportDriver.fromJson(const {
        'id': 7,
        'name': 'Tio Zé',
        'phone': '11988887777',
        'information': 'Van amarela',
        'cnh': '01234567890',
        'schools': ['Escola A'],
        'shifts': ['Manhã'],
        'shiftIds': [1],
      });

      expect(parsed.information, 'Van amarela');
      expect(parsed.districts, isEmpty);
      // Contato cai no `phone` (que o backend já envia como público).
      expect(parsed.contactPhone, '11988887777');
      // Sobre é o campo `information`.
      expect(parsed.about, 'Van amarela');
    });
  });

  group('PublicTransportDriverDetailSheet', () {
    testWidgets('renderiza descrição, van e bairros atendidos', (tester) async {
      await tester.pumpWidget(
        app(const PublicTransportDriverDetailSheet(driver: driver)),
      );
      await tester.pumpAndSettle();

      expect(find.text('José Motorista da Silva'), findsOneWidget);
      expect(
        find.text('Van com cadeirinha e monitora inclusa.'),
        findsOneWidget,
      );
      expect(find.textContaining('Fiat Ducato • Branca • 2020'), findsOneWidget);
      expect(find.text('Bairros atendidos'), findsOneWidget);
      expect(find.text('Centro'), findsOneWidget);
      // Escolas e turnos saíram do detalhe (payload enxuto).
      expect(find.text('Escolas atendidas'), findsNothing);
      expect(find.text('Turnos atendidos'), findsNothing);
      expect(find.textContaining('CNH'), findsNothing);
      // Contato público (nunca o telefone pessoal).
      expect(find.text('Chamar Tio Zé no WhatsApp'), findsOneWidget);
      expect(find.text('Ligar'), findsOneWidget);
    });

    testWidgets('oculta as seções de contato e descrição quando vazias', (
      tester,
    ) async {
      const semDetalhes = PublicTransportDriver(
        id: 7,
        name: 'José Motorista da Silva',
        cellPhone: null,
        information: null,
        avatarUrl: null,
        vehicleImageUrl: null,
        districts: ['Centro'],
      );

      await tester.pumpWidget(
        app(
          const PublicTransportDriverDetailSheet(driver: semDetalhes),
          searchResults: const [semDetalhes],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chamar Tio Zé no WhatsApp'), findsNothing);
      expect(find.text('Ligar'), findsNothing);
      expect(
        find.text('Este motorista ainda não cadastrou um contato público.'),
        findsOneWidget,
      );
      // Bairro continua visível em chips.
      expect(find.text('Centro'), findsOneWidget);
    });

    testWidgets('toque no card abre o bottom sheet de detalhe', (tester) async {
      await tester.pumpWidget(
        app(
          const SingleChildScrollView(
            child: PublicTransportDriverCard(driver: driver),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('José Motorista da Silva'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      // Contato público só aparece no detalhe (card mostra resumo).
      expect(find.text('Chamar Tio Zé no WhatsApp'), findsOneWidget);
    });

    testWidgets('banner da van usa proporção 4:3', (tester) async {
      const driverWithVehicle = PublicTransportDriver(
        id: 7,
        name: 'José Motorista da Silva',
        cellPhone: '11999998888',
        information: null,
        avatarUrl: null,
        vehicleImageUrl: 'https://example.com/van.jpg',
        districts: [],
      );
      await tester.pumpWidget(
        app(const PublicTransportDriverDetailSheet(driver: driverWithVehicle)),
      );
      await tester.pumpAndSettle();

      final aspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspectRatio.aspectRatio, closeTo(4 / 3, 0.001));
    });
  });
}
