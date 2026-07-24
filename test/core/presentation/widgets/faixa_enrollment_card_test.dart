import 'package:app_faixa_amarela/core/presentation/widgets/faixa_enrollment_card.dart';
import 'package:app_faixa_amarela/domain/models/enrollment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FaixaEnrollmentCard', () {
    const enrollment = Enrollment(
      id: 1,
      childId: 1,
      childName: 'Ana Silva',
      driverId: 2,
      driverName: 'Carlos Souza',
      vanPlate: 'ABC1D23',
      schoolName: 'Escola Exemplo',
      status: EnrollmentStatus.pending,
    );

    testWidgets('renders child, school and status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FaixaEnrollmentCard(enrollment: enrollment),
          ),
        ),
      );

      expect(find.text('Ana Silva'), findsOneWidget);
      expect(find.text('Escola Exemplo'), findsOneWidget);
      expect(find.text('Carlos Souza'), findsOneWidget);
      expect(find.text('ABC1D23'), findsOneWidget);
    });

    testWidgets('shows actions when showActions is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FaixaEnrollmentCard(
              enrollment: enrollment,
              showActions: true,
              onAccept: () {},
              onReject: () {},
            ),
          ),
        ),
      );

      expect(find.text('Aceitar'), findsOneWidget);
      expect(find.text('Recusar'), findsOneWidget);
    });

    testWidgets('calls onAccept when accept button is tapped', (tester) async {
      var accepted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FaixaEnrollmentCard(
              enrollment: enrollment,
              showActions: true,
              onAccept: () => accepted = true,
              onReject: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aceitar'));
      await tester.pump();

      expect(accepted, isTrue);
    });
  });
}
