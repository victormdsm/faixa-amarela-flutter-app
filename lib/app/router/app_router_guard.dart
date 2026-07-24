import '../../features/auth/domain/entities/auth_session.dart';
import '../../features/auth/domain/entities/user_role.dart';
import 'app_router.dart';

abstract final class AppRouterGuard {
  static String? redirect({
    required AuthSession? session,
    required bool isLoading,
    required String location,
    required UserRole? loginRole,
  }) {
    // Proteção contra location vazia durante inicialização do GoRouter.
    final loc = location.isEmpty ? AppRoutes.login : location;

    final isPublicRoute =
        loc == AppRoutes.login ||
        loc == AppRoutes.forgotPassword ||
        loc == AppRoutes.resetPassword ||
        loc == AppRoutes.parentSignUp ||
        loc == AppRoutes.finalizeRegistration ||
        loc == AppRoutes.searchTransport ||
        loc == AppRoutes.activation;

    if (isLoading) return null;

    if (session == null) {
      return isPublicRoute ? null : AppRoutes.login;
    }

    if (!session.user.isActivated) {
      return loc == AppRoutes.activation ? null : AppRoutes.activation;
    }

    // ── Roteamento baseado no endpoint de login ──────────────────────────
    //
    // [loginRole] indica qual endpoint foi usado: /auth/driver/login ou
    // /auth/user/login. Esta é a fonte de verdade — nunca use os roles do
    // backend para decidir o portal, pois um usuário pode ter múltiplos roles.
    //
    // Fallback (sessões antigas sem loginRole persistido): usa os roles.
    final isDriverSession = loginRole == UserRole.driver ||
        (loginRole == null &&
            session.user.isDriverAppRole &&
            !session.user.isParent);

    final isParentSession = loginRole == UserRole.parent ||
        (loginRole == null &&
            session.user.isParent &&
            !session.user.isDriverAppRole);

    final isDriverRoute = loc.startsWith('/motorista');
    final isParentRoute = loc.startsWith('/pais');

    // Impede motorista (neste contexto de login) de acessar portal de pais.
    if (isDriverSession && isParentRoute) return AppRoutes.driverHome;

    // Impede responsável (neste contexto de login) de acessar portal de motorista.
    if (isParentSession && isDriverRoute) return AppRoutes.parentHome;

    // Redireciona de rotas públicas para o portal correto.
    if (isPublicRoute) {
      if (isDriverSession) return AppRoutes.driverHome;
      if (isParentSession) return AppRoutes.parentHome;
    }

    return null;
  }
}
