import 'package:app_faixa_amarela/features/auth/domain/entities/auth_session.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_user.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/user_role.dart';
import 'package:app_faixa_amarela/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_faixa_amarela/features/auth/presentation/providers/auth_providers.dart';
import 'package:app_faixa_amarela/features/auth/presentation/state/app_session_controller.dart';
import 'package:app_faixa_amarela/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:app_faixa_amarela/features/tracking/presentation/state/driver_tracking_state.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  AuthSession? nextSession;
  int refreshCalls = 0;

  @override
  Future<AuthSession?> refreshCurrentSession() async {
    refreshCalls++;
    return nextSession;
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
    required UserRole role,
  }) => throw UnimplementedError();

  @override
  Future<void> activateAccount({
    required String emailOrCpf,
    required String code,
  }) => throw UnimplementedError();

  @override
  Future<void> requestActivationLink({required String login}) =>
      throw UnimplementedError();

  @override
  Future<void> requestPasswordReset({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) => throw UnimplementedError();

  @override
  Future<void> signUpParent({
    required String name,
    required String email,
    required String cpf,
    required String cellPhone,
    required String password,
    required String passwordConfirmation,
    bool acceptTerms = false,
  }) => throw UnimplementedError();
}

class _RecordingAppSessionController extends AppSessionController {
  final List<AuthSession> saved = <AuthSession>[];

  @override
  void setSession(AuthSession session, {required UserRole loginRole}) {
    saved.add(session);
    state = state.copyWith(
      session: session,
      isLoading: false,
      loginRole: loginRole,
    );
  }
}

AuthSession _session({required String token, required Duration expiresIn}) {
  return AuthSession(
    accessToken: token,
    tokenType: 'Bearer',
    refreshToken: 'refresh-$token',
    expiresAt: DateTime.now().add(expiresIn).toIso8601String(),
    user: AuthUser(
      id: 1,
      name: 'Motorista',
      email: 'motorista@email.com',
      roles: const ['driver'],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAuthRepository repository;
  late _RecordingAppSessionController sessionController;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    repository = _FakeAuthRepository();
    sessionController = _RecordingAppSessionController();
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        appSessionControllerProvider.overrideWith(() => sessionController),
      ],
    );
  }

  test('renova o token antes do expiresAt e sincroniza a nova sessao', () {
    fakeAsync((async) {
      final container = buildContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        driverTrackingControllerProvider.notifier,
      );
      controller.state = const DriverTrackingState(
        routeActive: true,
        routeId: 42,
        routeManifestId: 'route.42',
        vanId: 7,
      );

      repository.nextSession = _session(
        token: 'token-novo',
        expiresIn: const Duration(hours: 1),
      );
      controller.syncSession(
        _session(token: 'token-antigo', expiresIn: const Duration(hours: 1)),
      );

      expect(controller.proactiveRefreshScheduled, isTrue);
      expect(controller.authHeader, 'Bearer token-antigo');

      async.elapse(const Duration(minutes: 54));
      async.flushMicrotasks();
      expect(
        repository.refreshCalls,
        0,
        reason: 'a renovacao so ocorre perto do vencimento',
      );

      async.elapse(const Duration(minutes: 2));
      async.flushMicrotasks();

      expect(repository.refreshCalls, 1);
      expect(controller.authHeader, 'Bearer token-novo');
      expect(sessionController.saved.single.accessToken, 'token-novo');
      expect(
        container.read(appSessionControllerProvider).session?.accessToken,
        'token-novo',
      );
      expect(
        controller.proactiveRefreshScheduled,
        isTrue,
        reason: 'a proxima renovacao e reagendada com o novo expiresAt',
      );
    });
  });

  test('nao renova em paralelo', () {
    fakeAsync((async) {
      final container = buildContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        driverTrackingControllerProvider.notifier,
      );
      controller.state = const DriverTrackingState(
        routeActive: true,
        routeId: 42,
        routeManifestId: 'route.42',
        vanId: 7,
      );
      repository.nextSession = _session(
        token: 'token-novo',
        expiresIn: const Duration(hours: 1),
      );

      controller.refreshSessionNow();
      controller.refreshSessionNow();
      controller.refreshSessionNow();
      async.flushMicrotasks();

      expect(repository.refreshCalls, 1);
    });
  });

  test('sem rota ativa nao agenda nem renova', () {
    fakeAsync((async) {
      final container = buildContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        driverTrackingControllerProvider.notifier,
      );
      controller.syncSession(
        _session(token: 'token-antigo', expiresIn: const Duration(hours: 1)),
      );

      expect(controller.proactiveRefreshScheduled, isFalse);

      controller.refreshSessionNow();
      async.elapse(const Duration(hours: 2));
      async.flushMicrotasks();

      expect(repository.refreshCalls, 0);
    });
  });

  test('parar a rota cancela o timer de renovacao', () {
    fakeAsync((async) {
      final container = buildContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        driverTrackingControllerProvider.notifier,
      );
      controller.state = const DriverTrackingState(
        routeActive: true,
        routeId: 42,
        routeManifestId: 'route.42',
        vanId: 7,
      );
      controller.syncSession(
        _session(token: 'token-antigo', expiresIn: const Duration(hours: 1)),
      );
      expect(controller.proactiveRefreshScheduled, isTrue);

      controller.stopRouteTracking();
      async.flushMicrotasks();

      expect(controller.proactiveRefreshScheduled, isFalse);

      async.elapse(const Duration(hours: 2));
      async.flushMicrotasks();
      expect(repository.refreshCalls, 0);
    });
  });

  test('sessao nula no sign-out cancela o timer de renovacao', () {
    fakeAsync((async) {
      final container = buildContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        driverTrackingControllerProvider.notifier,
      );
      controller.state = const DriverTrackingState(
        routeActive: true,
        routeId: 42,
        routeManifestId: 'route.42',
        vanId: 7,
      );
      controller.syncSession(
        _session(token: 'token-antigo', expiresIn: const Duration(hours: 1)),
      );
      expect(controller.proactiveRefreshScheduled, isTrue);

      controller.syncSession(null);
      async.flushMicrotasks();

      expect(controller.proactiveRefreshScheduled, isFalse);

      async.elapse(const Duration(hours: 2));
      async.flushMicrotasks();
      expect(repository.refreshCalls, 0);
    });
  });
}
