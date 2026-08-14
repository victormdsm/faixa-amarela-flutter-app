import 'package:app_faixa_amarela/app/router/app_router.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_session.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_user.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/user_role.dart';
import 'package:app_faixa_amarela/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_faixa_amarela/features/auth/presentation/providers/auth_providers.dart';
import 'package:app_faixa_amarela/features/notifications/presentation/providers/notification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoOpPushRegistrationService extends PushRegistrationService {
  _NoOpPushRegistrationService(super.ref);

  @override
  Future<void> registerCurrentDevice(String authHeader) async {}
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return AuthSession(
      accessToken: 'driver-token',
      tokenType: 'Bearer',
      user: AuthUser(
        id: 1,
        name: 'Driver',
        email: 'driver@email.com',
        roles: const ['driver'],
        isActivated: true,
      ),
    );
  }

  @override
  Future<AuthSession?> refreshCurrentSession() async => null;

  @override
  Future<void> activateAccount({
    required String emailOrCpf,
    required String code,
  }) async {}

  @override
  Future<void> requestActivationLink({required String login}) async {}

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {}

  @override
  Future<void> signUpParent({
    required String name,
    required String email,
    required String cpf,
    required String cellPhone,
    required String password,
    required String passwordConfirmation,
    bool acceptTerms = false,
  }) async {}
}

void main() {
  group('Driver login redirect via GoRouter', () {
    testWidgets('login flow submits and redirects driver to /motorista',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          pushRegistrationServiceProvider.overrideWith((ref) {
            return _NoOpPushRegistrationService(ref);
          }),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select driver role.
      await tester.tap(find.text('Tio da Van'));
      await tester.pumpAndSettle();

      // Fill credentials (login somente por e-mail).
      await tester.enterText(
        find.byKey(const Key('email_input')),
        'driver@email.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_input')),
        'anypassword',
      );
      await tester.pump();

      // Submit login.
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final currentPath = router.routerDelegate.currentConfiguration.uri.path;

      expect(currentPath, '/motorista');
    });
  });
}
