import 'dart:io';

import 'package:app_faixa_amarela/app/theme/app_theme.dart';
import 'package:app_faixa_amarela/domain/models/child.dart';
import 'package:app_faixa_amarela/domain/models/enrollment.dart';
import 'package:app_faixa_amarela/features/auth/data/session_storage.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_session.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_user.dart';
import 'package:app_faixa_amarela/features/auth/presentation/state/app_session_controller.dart';
import 'package:app_faixa_amarela/features/parent_portal/presentation/pages/parent_children_page.dart';
import 'package:app_faixa_amarela/features/parent_portal/presentation/pages/parent_enrollments_page.dart';
import 'package:app_faixa_amarela/features/parent_portal/presentation/providers/parent_portal_providers.dart';
import 'package:app_faixa_amarela/ui/core/widgets/child_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import '../test/fakes/fake_children_repository.dart';
import '../test/fakes/fake_enrollments_repository.dart';

void main() {
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    final tempDir = Directory.systemTemp.createTempSync('hive_int_test');
    Hive.init(tempDir.path);
    await SessionStorage.openBox();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('parent: login -> list children -> accept enrollment', (
    tester,
  ) async {
    final childrenRepo = FakeChildrenRepository();
    final enrollmentsRepo = FakeEnrollmentsRepository();

    childrenRepo.addChild(
      Child(
        id: 1,
        name: 'Ana Silva',
        cpf: '12345678901',
        birthDate: DateTime(2015, 3, 10),
        schoolName: 'Escola Primavera',
        shiftId: 1,
        shiftName: 'Manhã',
        parentId: 1,
        parentName: 'Maria Silva',
        address: ChildAddress(
          street: 'Rua das Flores',
          number: '100',
          neighborhood: 'Jardim',
          city: 'São Paulo',
          state: 'SP',
          zipCode: '01001000',
        ),
      ),
    );

    enrollmentsRepo.addEnrollment(
      Enrollment(
        id: 1,
        childId: 1,
        childName: 'Ana Silva',
        driverId: 5,
        driverName: 'José Motorista',
        vanPlate: 'ABC1234',
        schoolName: 'Escola Primavera',
        status: EnrollmentStatus.pending,
        requestedAt: DateTime.now(),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        childrenRepositoryProvider.overrideWithValue(childrenRepo),
        enrollmentsRepositoryProvider.overrideWithValue(enrollmentsRepo),
      ],
    );

    final session = AuthSession(
      accessToken: 'tok',
      tokenType: 'Bearer',
      user: AuthUser(
        id: 1,
        name: 'Maria',
        email: 'm@e.com',
        role: 'user',
        isActivated: true,
      ),
    );
    container.read(appSessionControllerProvider.notifier).setSession(session);
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ParentChildrenPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChildSummaryCard), findsOneWidget);
    expect(find.text('Ana Silva'), findsOneWidget);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ParentEnrollmentsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana Silva'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);

    await enrollmentsRepo.acceptEnrollment(1);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ParentEnrollmentsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final enrollments = await enrollmentsRepo.getPendingEnrollments();
    expect(enrollments.isEmpty, true);
  });
}
