import 'package:app_faixa_amarela/app/router/app_router.dart';
import 'package:app_faixa_amarela/app/router/app_router_guard.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_session.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

AuthSession _session({
  required String role,
  bool activated = true,
  String? email,
}) {
  return AuthSession(
    accessToken: 'token',
    tokenType: 'Bearer',
    user: AuthUser(
      id: 1,
      name: 'User',
      email: email ?? 'user@email.com',
      role: role,
      isActivated: activated,
    ),
  );
}

void main() {
  group('AppRouterGuard.redirect', () {
    test('returns null while loading', () {
      expect(
        AppRouterGuard.redirect(
          session: null,
          isLoading: true,
          location: AppRoutes.driverHome,
        ),
        isNull,
      );
    });

    test('anonymous accessing protected route is redirected to login', () {
      expect(
        AppRouterGuard.redirect(
          session: null,
          isLoading: false,
          location: AppRoutes.parentHome,
        ),
        AppRoutes.login,
      );
    });

    test('anonymous accessing public route stays', () {
      expect(
        AppRouterGuard.redirect(
          session: null,
          isLoading: false,
          location: AppRoutes.login,
        ),
        isNull,
      );
    });

    test('non-activated user is redirected to activation page', () {
      final session = _session(role: 'user', activated: false);
      expect(
        AppRouterGuard.redirect(
          session: session,
          isLoading: false,
          location: AppRoutes.parentHome,
        ),
        AppRoutes.activation,
      );
    });

    test('non-activated user can stay on activation page', () {
      final session = _session(role: 'user', activated: false);
      expect(
        AppRouterGuard.redirect(
          session: session,
          isLoading: false,
          location: AppRoutes.activation,
        ),
        isNull,
      );
    });

    test('parent accessing driver route is redirected to parent home', () {
      final session = _session(role: 'user');
      expect(
        AppRouterGuard.redirect(
          session: session,
          isLoading: false,
          location: AppRoutes.driverHome,
        ),
        AppRoutes.parentHome,
      );
      expect(
        AppRouterGuard.redirect(
          session: session,
          isLoading: false,
          location: AppRoutes.driverRoutes,
        ),
        AppRoutes.parentHome,
      );
    });

    test('driver accessing parent route is redirected to driver home', () {
      final session = _session(role: 'driver');
      expect(
        AppRouterGuard.redirect(
          session: session,
          isLoading: false,
          location: AppRoutes.parentHome,
        ),
        AppRoutes.driverHome,
      );
      expect(
        AppRouterGuard.redirect(
          session: session,
          isLoading: false,
          location: AppRoutes.parentChildren,
        ),
        AppRoutes.driverHome,
      );
    });

    test('parent accessing parent route is allowed', () {
      final session = _session(role: 'user');
      expect(
        AppRouterGuard.redirect(
          session: session,
          isLoading: false,
          location: AppRoutes.parentHome,
        ),
        isNull,
      );
    });

    test('driver accessing driver route is allowed', () {
      final session = _session(role: 'driver');
      expect(
        AppRouterGuard.redirect(
          session: session,
          isLoading: false,
          location: AppRoutes.driverHome,
        ),
        isNull,
      );
    });

    test('authenticated user on public route is redirected to their home', () {
      final parentSession = _session(role: 'user');
      final driverSession = _session(role: 'driver');

      expect(
        AppRouterGuard.redirect(
          session: parentSession,
          isLoading: false,
          location: AppRoutes.login,
        ),
        AppRoutes.parentHome,
      );

      expect(
        AppRouterGuard.redirect(
          session: driverSession,
          isLoading: false,
          location: AppRoutes.login,
        ),
        AppRoutes.driverHome,
      );
    });
  });
}
