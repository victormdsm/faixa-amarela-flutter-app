import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_role.dart';

class AppSessionState {
  const AppSessionState({this.session, this.isLoading = false, this.loginRole});

  final AuthSession? session;
  final bool isLoading;

  /// Qual endpoint foi usado no login: [UserRole.driver] ou [UserRole.parent].
  ///
  /// É a fonte de verdade para roteamento quando o usuário possui múltiplos
  /// roles (ex: motorista que também é responsável). Nunca use os roles do
  /// [AuthSession.user] para decidir para qual shell navegar — use este campo.
  ///
  /// Persistido no Hive via [SessionStorage.save] para sobreviver a restarts.
  final UserRole? loginRole;

  bool get isAuthenticated => session != null;

  AppSessionState copyWith({
    AuthSession? session,
    bool? isLoading,
    bool clearSession = false,
    UserRole? loginRole,
    bool clearLoginRole = false,
  }) {
    return AppSessionState(
      session: clearSession ? null : (session ?? this.session),
      isLoading: isLoading ?? this.isLoading,
      loginRole: clearLoginRole ? null : (loginRole ?? this.loginRole),
    );
  }
}
