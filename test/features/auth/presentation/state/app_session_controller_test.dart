import 'dart:io';

import 'package:app_faixa_amarela/features/auth/data/repositories/nestjs_auth_repository.dart';
import 'package:app_faixa_amarela/features/auth/data/session_storage.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_session.dart';
import 'package:app_faixa_amarela/features/auth/presentation/providers/auth_providers.dart';
import 'package:app_faixa_amarela/features/driver_portal/data/driver_profile_storage.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_user.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/user_role.dart';
import 'package:app_faixa_amarela/features/auth/presentation/state/app_session_controller.dart';
import 'package:app_faixa_amarela/features/driver_portal/presentation/providers/driver_portal_providers.dart';
import 'package:app_faixa_amarela/core/storage/secure_token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Logout remoto é best-effort; em teste ele é um no-op para não bater na rede.
class _FakeAuthRepository extends NestjsAuthRepository {
  _FakeAuthRepository() : super(Dio(), SecureTokenStorage());

  int logoutCalls = 0;

  @override
  Future<void> logout({String? refreshToken, bool allDevices = false}) async {
    logoutCalls++;
  }
}

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

  test(
    'signOut zera a sessão e reseta o guard de perfil (APP-07: sem vazamento de PII entre contas)',
    () async {
      final fakeAuth = _FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuth),
        ],
      );
      final controller = container.read(appSessionControllerProvider.notifier);

      final session = AuthSession(
        accessToken: 'tok',
        tokenType: 'Bearer',
        refreshToken: 'refresh',
        user: AuthUser(id: 7, name: 'User', email: 'u@e.com', roles: ['user']),
      );
      controller.setSession(session, loginRole: UserRole.driver);
      await pumpEventQueue();

      // Simula uma sessão com perfil já entregue: o guard registra o userId
      // e sobreviveria ao logout sem a invalidação do APP-07.
      container.read(driverProfileSessionGuardProvider).loadedUserId = 7;

      await controller.signOut();
      await pumpEventQueue();

      expect(container.read(appSessionControllerProvider).session, isNull);
      // Guard recriado limpo: o próximo login é tratado como primeira carga.
      expect(
        container.read(driverProfileSessionGuardProvider).loadedUserId,
        isNull,
      );
      expect(fakeAuth.logoutCalls, 1);

      addTearDown(container.dispose);
    },
  );

  test('clear também reseta o guard de perfil (logout forçado por 401)', () async {
    final container = ProviderContainer();
    final controller = container.read(appSessionControllerProvider.notifier);

    controller.setSession(
      AuthSession(
        accessToken: 'tok',
        tokenType: 'Bearer',
        user: AuthUser(id: 9, name: 'User', email: 'u@e.com', roles: ['user']),
      ),
      loginRole: UserRole.driver,
    );
    await pumpEventQueue();
    container.read(driverProfileSessionGuardProvider).loadedUserId = 9;

    await controller.clear();
    await pumpEventQueue();

    expect(
      container.read(driverProfileSessionGuardProvider).loadedUserId,
      isNull,
    );

    addTearDown(container.dispose);
  });
}
