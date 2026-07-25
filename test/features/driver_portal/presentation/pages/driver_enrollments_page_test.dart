import 'package:app_faixa_amarela/domain/models/enrollment.dart';
import 'package:app_faixa_amarela/features/driver_portal/presentation/pages/driver_enrollments_page.dart';
import 'package:app_faixa_amarela/features/driver_portal/presentation/providers/driver_portal_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_enrollments_repository.dart';

Enrollment _enrollment({
  required int id,
  required String childName,
  required EnrollmentStatus status,
}) {
  return Enrollment(
    id: id,
    childId: id * 10,
    childName: childName,
    driverId: 1,
    driverName: 'Motorista',
    vanPlate: 'ABC1234',
    schoolName: 'Escola Teste',
    status: status,
    requestedAt: DateTime(2026, 1, 1),
  );
}

Widget _buildPage(FakeEnrollmentsRepository repository) {
  return ProviderScope(
    overrides: [
      driverEnrollmentsRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(home: DriverEnrollmentsPage()),
  );
}

void main() {
  testWidgets('shows Desvincular action for active and pending enrollments',
      (tester) async {
    final repository = FakeEnrollmentsRepository()
      ..addEnrollment(
        _enrollment(
          id: 1,
          childName: 'Ana Ativa',
          status: EnrollmentStatus.active,
        ),
      )
      ..addEnrollment(
        _enrollment(
          id: 2,
          childName: 'Pedro Pendente',
          status: EnrollmentStatus.pending,
        ),
      );

    await tester.pumpWidget(_buildPage(repository));
    await tester.pumpAndSettle();

    expect(find.text('Ana Ativa'), findsOneWidget);
    expect(find.text('Pedro Pendente'), findsOneWidget);
    expect(find.text('Desvincular'), findsNWidgets(2));
  });

  testWidgets('confirming the dialog unlinks the enrollment and removes it '
      'from the list', (tester) async {
    final repository = FakeEnrollmentsRepository()
      ..addEnrollment(
        _enrollment(
          id: 1,
          childName: 'Ana Ativa',
          status: EnrollmentStatus.active,
        ),
      )
      ..addEnrollment(
        _enrollment(
          id: 2,
          childName: 'Pedro Pendente',
          status: EnrollmentStatus.pending,
        ),
      );

    await tester.pumpWidget(_buildPage(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Desvincular').first);
    await tester.pumpAndSettle();

    expect(find.text('Desvincular criança'), findsOneWidget);
    expect(find.textContaining('sairá da sua lista'), findsOneWidget);
    expect(find.textContaining('O responsável será informado.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Desvincular'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Ativa'), findsNothing);
    expect(find.text('Pedro Pendente'), findsOneWidget);
    expect(find.text('Matrícula desvinculada.'), findsOneWidget);
  });

  testWidgets('dismissing the dialog keeps the enrollment in the list',
      (tester) async {
    final repository = FakeEnrollmentsRepository()
      ..addEnrollment(
        _enrollment(
          id: 1,
          childName: 'Ana Ativa',
          status: EnrollmentStatus.active,
        ),
      );

    await tester.pumpWidget(_buildPage(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Desvincular'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Ativa'), findsOneWidget);
    expect(find.text('Desvincular'), findsOneWidget);
  });
}
