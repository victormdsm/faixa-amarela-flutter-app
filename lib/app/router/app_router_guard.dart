import '../../features/auth/domain/entities/auth_session.dart';
import 'app_router.dart';

abstract final class AppRouterGuard {
  static String? redirect({
    required AuthSession? session,
    required bool isLoading,
    required String location,
  }) {
    final isPublicRoute =
        location == AppRoutes.login ||
        location == AppRoutes.forgotPassword ||
        location == AppRoutes.parentSignUp ||
        location == AppRoutes.finalizeRegistration ||
        location == AppRoutes.searchTransport ||
        location == AppRoutes.activation;

    if (isLoading) return null;

    if (session == null) {
      return isPublicRoute ? null : AppRoutes.login;
    }

    if (!session.user.isActivated) {
      return location == AppRoutes.activation ? null : AppRoutes.activation;
    }

    final isDriverRoute = location.startsWith('/motorista');
    final isParentRoute = location.startsWith('/pais');

    if (session.user.isParent && isDriverRoute) {
      return AppRoutes.parentHome;
    }
    if (session.user.isDriverAppRole && isParentRoute) {
      return AppRoutes.driverHome;
    }

    if (isPublicRoute) {
      if (session.user.isParent) return AppRoutes.parentHome;
      if (session.user.isDriverAppRole) return AppRoutes.driverHome;
    }

    return null;
  }
}
