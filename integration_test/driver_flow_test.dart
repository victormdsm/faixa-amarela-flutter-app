import 'dart:io';

import 'package:app_faixa_amarela/app/theme/app_theme.dart';
import 'package:app_faixa_amarela/domain/models/enrollment.dart';
import 'package:app_faixa_amarela/domain/repositories/enrollments_repository.dart';
import 'package:app_faixa_amarela/features/auth/data/session_storage.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_session.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_user.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/user_role.dart';
import 'package:app_faixa_amarela/features/auth/presentation/state/app_session_controller.dart';
import 'package:app_faixa_amarela/features/driver_portal/presentation/pages/driver_lookup_child_page.dart';
import 'package:app_faixa_amarela/features/driver_portal/presentation/providers/driver_portal_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

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

  testWidgets('driver: login -> lookup child by code (UUID) -> request enrollment', (
    tester,
  ) async {
    final enrollmentsRepo = FakeEnrollmentsRepository();
    enrollmentsRepo.setLookupResult(
      ChildLookupResult(
        found: true,
        childId: 10,
        childName: 'Ana Silva',
        parentName: 'Maria Silva',
        address: 'Rua das Flores, 100',
        schoolName: 'Escola Primavera',
        shiftName: 'Manhã',
        isInDebt: false,
        hasPendingEnrollment: false,
      ),
    );

    final container = ProviderContainer(
      overrides: [
        driverEnrollmentsRepositoryProvider.overrideWithValue(enrollmentsRepo),
      ],
    );

    final session = AuthSession(
      accessToken: 'tok',
      tokenType: 'Bearer',
      user: AuthUser(
        id: 5,
        name: 'José',
        email: 'j@e.com',
        roles: ['driver'],
        isActivated: true,
      ),
    );
    container.read(appSessionControllerProvider.notifier).setSession(session, loginRole: UserRole.driver);
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DriverLookupChildPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      'a1b2c3d4-e5f6-4a1b-8c2d-9e0f1a2b3c4d',
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Ana Silva'), findsOneWidget);

    await enrollmentsRepo.requestEnrollment(10);
    final enrollments = await enrollmentsRepo.getMyEnrollments();
    expect(enrollments.length, 1);
    expect(enrollments.first.status, EnrollmentStatus.pending);
  });
}
