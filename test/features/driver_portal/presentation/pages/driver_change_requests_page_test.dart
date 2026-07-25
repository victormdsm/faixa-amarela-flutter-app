import 'package:app_faixa_amarela/core/models/catalog_option.dart';
import 'package:app_faixa_amarela/domain/models/driver_profile_change_request.dart';
import 'package:app_faixa_amarela/features/catalog/data/catalog_repository.dart';
import 'package:app_faixa_amarela/features/driver_portal/presentation/pages/driver_change_requests_page.dart';
import 'package:app_faixa_amarela/features/driver_portal/presentation/providers/driver_portal_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  testWidgets(
    'lista renderiza sem overflow com nomes longos em tela estreita',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const longSchool1 =
          'Escola Municipal Professor Joaquim da Silva Sauro Filho';
      const longSchool2 =
          'Colegio Estadual Dona Maria Thereza de Jesus e Santana';
      const longDistrict = 'Jardim das Acacias do Parque Residencial das Flores';
      const longShift1 = 'Matutino integral estendido';
      const longShift2 = 'Vespertino com reforco';

      final request = DriverProfileChangeRequest(
        id: 1,
        driverUserId: 1,
        requestedByUserId: 1,
        status: 'pending',
        requestedSchoolIds: const [1, 2],
        requestedDistrictShiftMap: const {
          '10': [100, 101],
          '11': [100],
        },
        requestedAvatarPath: 'avatar.png',
        requestedVehicleImagePath: 'veiculo.png',
        requestNote:
            'Observacao enviada pelo motorista com texto longo explicando '
            'todos os detalhes da alteracao solicitada para o transporte.',
        reviewNote:
            'Observacao do admin tambem longa, detalhando o motivo da '
            'analise e orientacoes para o motorista responsavel.',
        createdAt: DateTime(2026, 7, 24, 20, 30),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            driverProfileChangeRequestsProvider.overrideWith(
              (ref) async => [request],
            ),
            schoolsCatalogProvider.overrideWith(
              (ref) async => const [
                CatalogOption(id: 1, name: longSchool1),
                CatalogOption(id: 2, name: longSchool2),
              ],
            ),
            districtsCatalogProvider.overrideWith(
              (ref) async => const [
                CatalogOption(id: 10, name: longDistrict),
                CatalogOption(id: 11, name: longDistrict),
              ],
            ),
            shiftsCatalogProvider.overrideWith(
              (ref) async => const [
                CatalogOption(id: 100, name: longShift1),
                CatalogOption(id: 101, name: longShift2),
              ],
            ),
          ],
          child: const MaterialApp(home: DriverChangeRequestsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining(longSchool1), findsOneWidget);
      expect(find.textContaining('Motivo da reprovacao'), findsNothing);
    },
  );
}
