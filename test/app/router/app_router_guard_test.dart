import 'package:app_faixa_amarela/app/router/app_router.dart';
import 'package:app_faixa_amarela/app/router/app_router_guard.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_session.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

AuthSession _session({
  required String role,
  bool isActivated = true,
  String? email,
}) {
  return AuthSession(
    accessToken: 'token',
    tokenType: 'Bearer',
    user: AuthUser(
      id: 1,
      name: 'User',
      email: email ?? 'user@email.com',
      roles: [role],
      isActivated: isActivated,
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
          loginRole: null,
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
          loginRole: null,
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
          loginRole: null,
          location: AppRoutes.login,
        ),
        isNull,
      );
    });

    test('non-activated user is redirected to activation page', () {
      final session = _session(role: 'user', isActivated: false);
      expect(
        AppRouterGuard.redirect(
          session: session,
          isLoading: false,
          loginRole: null,
          location: AppRoutes.parentHome,
        ),
        AppRoutes.activation,
      );
    });

    test('non-activated user can stay on activation page', () {
      final session = _session(role: 'user', isActivated: false);
      expect(
        AppRouterGuard.redirect(
          session: session,
          isLoading: false,
          loginRole: null,
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
          loginRole: null,
          location: AppRoutes.driverHome,
        ),
        AppRoutes.parentHome,
      );
      expect(
        AppRouterGuard.redirect(
          session: session,
          isLoading: false,
          loginRole: null,
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
          loginRole: null,
          location: AppRoutes.parentHome,
        ),
        AppRoutes.driverHome,
      );
      expect(
        AppRouterGuard.redirect(
          session: session,
          isLoading: false,
          loginRole: null,
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
          loginRole: null,
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
          loginRole: null,
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
          loginRole: null,
          location: AppRoutes.login,
        ),
        AppRoutes.parentHome,
      );

      expect(
        AppRouterGuard.redirect(
          session: driverSession,
          isLoading: false,
          loginRole: null,
          location: AppRoutes.login,
        ),
        AppRoutes.driverHome,
      );
    });

    test('reset password is treated as public route', () {
      expect(
        AppRouterGuard.redirect(
          session: null,
          isLoading: false,
          loginRole: null,
          location: AppRoutes.resetPassword,
        ),
        isNull,
      );

      final parentSession = _session(role: 'parent');
      expect(
        AppRouterGuard.redirect(
          session: parentSession,
          isLoading: false,
          loginRole: null,
          location: AppRoutes.resetPassword,
        ),
        AppRoutes.parentHome,
      );
    });

    test('parent role also matches user role', () {
      final parentSession = _session(role: 'parent');
      final userSession = _session(role: 'user');

      expect(parentSession.user.isParent, isTrue);
      expect(userSession.user.isParent, isTrue);
      expect(
        AppRouterGuard.redirect(
          session: parentSession,
          isLoading: false,
          loginRole: null,
          location: AppRoutes.login,
        ),
        AppRoutes.parentHome,
      );
      expect(
        AppRouterGuard.redirect(
          session: userSession,
          isLoading: false,
          loginRole: null,
          location: AppRoutes.login,
        ),
        AppRoutes.parentHome,
      );
    });

    test('parent stays on any parent portal sub-route', () {
      final session = _session(role: 'user');
      for (final location in [
        AppRoutes.parentHome,
        AppRoutes.parentChildren,
        AppRoutes.parentRoutes,
        AppRoutes.parentBoardings,
        AppRoutes.parentEnrollments,
        AppRoutes.parentNotifications,
      ]) {
        expect(
          AppRouterGuard.redirect(
            session: session,
            isLoading: false,
            loginRole: null,
            location: location,
          ),
          isNull,
          reason: '$location should be allowed for parents',
        );
      }
    });

    test('driver stays on any driver portal sub-route', () {
      final session = _session(role: 'driver');
      for (final location in [
        AppRoutes.driverHome,
        AppRoutes.driverClients,
        AppRoutes.driverAddClient,
        AppRoutes.driverRoutes,
        AppRoutes.driverNotifications,
        AppRoutes.driverRouteExecution,
        AppRoutes.driverEnrollments,
        AppRoutes.driverSettings,
      ]) {
        expect(
          AppRouterGuard.redirect(
            session: session,
            isLoading: false,
            loginRole: null,
            location: location,
          ),
          isNull,
          reason: '$location should be allowed for drivers',
        );
      }
    });

    test('driver is redirected from any parent route to driver home', () {
      final session = _session(role: 'driver');
      for (final location in [
        AppRoutes.parentHome,
        AppRoutes.parentChildren,
        AppRoutes.parentRoutes,
        AppRoutes.parentBoardings,
        AppRoutes.parentEnrollments,
        AppRoutes.parentNotifications,
      ]) {
        expect(
          AppRouterGuard.redirect(
            session: session,
            isLoading: false,
            loginRole: null,
            location: location,
          ),
          AppRoutes.driverHome,
          reason: '$location should redirect drivers to ${AppRoutes.driverHome}',
        );
      }
    });

    test('parent is redirected from any driver route to parent home', () {
      final session = _session(role: 'parent');
      for (final location in [
        AppRoutes.driverHome,
        AppRoutes.driverClients,
        AppRoutes.driverAddClient,
        AppRoutes.driverRoutes,
        AppRoutes.driverNotifications,
        AppRoutes.driverRouteExecution,
        AppRoutes.driverEnrollments,
        AppRoutes.driverSettings,
      ]) {
        expect(
          AppRouterGuard.redirect(
            session: session,
            isLoading: false,
            loginRole: null,
            location: location,
          ),
          AppRoutes.parentHome,
          reason: '$location should redirect parents to ${AppRoutes.parentHome}',
        );
      }
    });
  });
}
