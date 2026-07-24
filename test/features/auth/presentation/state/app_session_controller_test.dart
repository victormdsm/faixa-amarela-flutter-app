import 'dart:io';

import 'package:app_faixa_amarela/features/auth/data/session_storage.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_session.dart';
import 'package:app_faixa_amarela/features/driver_portal/data/driver_profile_storage.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_user.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/user_role.dart';
import 'package:app_faixa_amarela/features/auth/presentation/state/app_session_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('hive_test');
    Hive.init(tempDir.path);
    await SessionStorage.openBox();
    await DriverProfileStorage.openBox();
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test('AppSessionController setSession updates state', () async {
    final container = ProviderContainer();
    final controller = container.read(appSessionControllerProvider.notifier);

    final session = AuthSession(
      accessToken: 'tok',
      tokenType: 'Bearer',
      user: AuthUser(id: 1, name: 'User', email: 'u@e.com', roles: ['user']),
    );

    controller.setSession(session, loginRole: UserRole.parent);
    await pumpEventQueue();

    expect(container.read(appSessionControllerProvider).session, isNotNull);
    expect(
      container.read(appSessionControllerProvider).session?.accessToken,
      'tok',
    );

    addTearDown(container.dispose);
  });

  test('AppSessionController clear resets state', () async {
    final container = ProviderContainer();
    final controller = container.read(appSessionControllerProvider.notifier);

    final session = AuthSession(
      accessToken: 'tok',
      tokenType: 'Bearer',
      user: AuthUser(id: 1, name: 'User', email: 'u@e.com', roles: ['user']),
    );

    controller.setSession(session, loginRole: UserRole.parent);
    await pumpEventQueue();
    await controller.clear();
    await pumpEventQueue();

    expect(container.read(appSessionControllerProvider).session, isNull);

    addTearDown(container.dispose);
  });
}
