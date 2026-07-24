import 'dart:io';

import 'package:app_faixa_amarela/app/router/app_router.dart';
import 'package:app_faixa_amarela/app/theme/app_theme.dart';
import 'package:app_faixa_amarela/core/storage/secure_token_storage.dart';
import 'package:app_faixa_amarela/features/auth/data/session_storage.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_session.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_user.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/user_role.dart';
import 'package:app_faixa_amarela/features/auth/presentation/providers/auth_providers.dart';
import 'package:app_faixa_amarela/features/auth/presentation/state/app_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

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

  testWidgets('logout clears token and blocks authenticated screen', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        secureTokenStorageProvider.overrideWithValue(SecureTokenStorage()),
      ],
    );

    final session = AuthSession(
      accessToken: 'test_token',
      tokenType: 'Bearer',
      user: AuthUser(
        id: 1,
        name: 'User',
        email: 'u@e.com',
        roles: ['user'],
        isActivated: true,
      ),
    );
    container.read(appSessionControllerProvider.notifier).setSession(session, loginRole: UserRole.parent);
    await tester.pumpAndSettle();

    final router = container.read(appRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pais'), findsWidgets);

    container.read(appSessionControllerProvider.notifier).clear();
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsWidgets);
  });
}
