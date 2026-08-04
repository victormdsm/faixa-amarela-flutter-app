import 'package:app_faixa_amarela/domain/repositories/enrollments_repository.dart';
import 'package:app_faixa_amarela/features/driver_portal/presentation/pages/driver_lookup_child_page.dart';
import 'package:app_faixa_amarela/features/driver_portal/presentation/providers/driver_portal_providers.dart';
import 'package:app_faixa_amarela/features/driver_portal/presentation/state/driver_lookup_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_enrollments_repository.dart';

class _StubEnrollmentsRepository extends FakeEnrollmentsRepository {
  String? lastLookupCode;

  @override
  Future<ChildLookupResult> lookupChildByCode(String code) async {
    lastLookupCode = code;
    return const ChildLookupResult(found: true, childId: 10, childName: 'Ana');
  }
}

void main() {
  const validUuid = 'a1b2c3d4-e5f6-4a1b-8c2d-9e0f1a2b3c4d';

  testWidgets('campo aceita uuid e rejeita cpf com hint', (tester) async {
    final repository = _StubEnrollmentsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          driverEnrollmentsRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: DriverLookupChildPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Campo pede exclusivamente o código, com instrução de onde encontrá-lo.
    expect(find.text('Código da criança'), findsOneWidget);
    expect(
      find.text('Perfil da criança → código para compartilhar'),
      findsOneWidget,
    );
    expect(find.textContaining('CPF'), findsNothing);

    // CPF não é aceito: hint de validação local e nenhuma chamada à API.
    await tester.enterText(find.byType(TextField).first, '123.456.789-09');
    await tester.pump();
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();

    expect(
      find.text(DriverLookupController.invalidCodeMessage),
      findsOneWidget,
    );
    expect(repository.lastLookupCode, isNull);

    // UUID válido dispara o lookup e exibe o resultado.
    await tester.enterText(find.byType(TextField).first, validUuid);
    await tester.pump();
    await tester.tap(find.text('Buscar'));
    await tester.pump(const Duration(milliseconds: 700)); // debouncer
    await tester.pumpAndSettle();

    expect(repository.lastLookupCode, validUuid);
    expect(find.text('Ana'), findsOneWidget);
  });
}
