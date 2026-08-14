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

    // Busca pública de transporte: acessível sem login E também com a sessão
    // aberta (o responsável abre pelo CTA "Encontrar transporte escolar" da
    // home). Fica fora de [isPublicRoute] porque rotas públicas são
    // *redirecionadas de volta* ao portal quando há sessão — era isso que
    // fazia o botão da home do responsável não sair do lugar.
    final isOpenRoute = loc == AppRoutes.searchTransport;

    final isPublicRoute =
        isOpenRoute ||
        loc == AppRoutes.login ||
        loc == AppRoutes.forgotPassword ||
        loc == AppRoutes.resetPassword ||
        loc == AppRoutes.parentSignUp ||
        loc == AppRoutes.finalizeRegistration ||
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

    // Redireciona de rotas públicas para o portal correto — exceto as rotas
    // abertas, que continuam navegáveis com a sessão ativa.
    if (isPublicRoute && !isOpenRoute) {
      if (isDriverSession) return AppRoutes.driverHome;
      if (isParentSession) return AppRoutes.parentHome;
    }

    return null;
  }
}
