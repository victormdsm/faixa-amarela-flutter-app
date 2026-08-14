import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ads/presentation/providers/ads_providers.dart';
import '../../../driver_portal/data/driver_profile_storage.dart';
import '../../../driver_portal/presentation/providers/driver_portal_providers.dart';
import '../../../parent_portal/presentation/providers/parent_portal_providers.dart';
import '../../data/repositories/nestjs_auth_repository.dart';
import '../../data/session_storage.dart';
import '../../../tracking/data/driver_tracking_runtime.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_role.dart';
import '../providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import 'app_session_state.dart';

final _sessionStorageProvider = Provider<SessionStorage>(
  (ref) => SessionStorage(secureStorage: ref.watch(secureTokenStorageProvider)),
);

final appSessionControllerProvider =
    NotifierProvider<AppSessionController, AppSessionState>(
      AppSessionController.new,
    );

class AppSessionController extends Notifier<AppSessionState> {
  @override
  AppSessionState build() {
    // Bootstrap assíncrono: o token está no secure storage; metadados no Hive.
    // Chame [loadFromStorage] no initState do app para completar o carregamento.
    return const AppSessionState(session: null, isLoading: true);
  }

  Future<void> loadFromStorage() async {
    final stored = await ref.read(_sessionStorageProvider).load();
    final loginRole = ref.read(_sessionStorageProvider).loadLoginRole();
    state = AppSessionState(
      session: stored,
      isLoading: false,
      loginRole: loginRole,
    );

    if (stored != null) {
      try {
        await ref
            .read(pushRegistrationServiceProvider)
            .registerCurrentDevice(stored.authorizationHeader);
      } catch (_) {
        // Ignore push registration errors on startup.
      }
    }
  }

  void setSession(AuthSession session, {required UserRole loginRole}) {
    state = state.copyWith(
      session: session,
      isLoading: false,
      loginRole: loginRole,
    );
    unawaited(
      ref.read(_sessionStorageProvider).save(session, loginRole: loginRole),
    );
  }

  void updateCurrentUser({String? name}) {
    final current = state.session;
    if (current == null) return;

    final updatedUser = current.user.copyWith(
      name: name,
    );
    final updated = AuthSession(
      accessToken: current.accessToken,
      tokenType: current.tokenType,
      user: updatedUser,
      refreshToken: current.refreshToken,
      expiresAt: current.expiresAt,
      refreshExpiresAt: current.refreshExpiresAt,
    );
    // Preserva o loginRole atual: atualizar dados pessoais não muda o portal.
    setSession(updated, loginRole: state.loginRole ?? UserRole.parent);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  Future<void> clear() async {
    state = const AppSessionState(session: null, isLoading: false);
    await ref.read(_sessionStorageProvider).clear();
    await DriverProfileStorage().clear();
    // Limpa o buffer de telemetria independentemente do estado da rota;
    // evita que pontos de GPS fiquem congelados no disco entre contas.
    await clearDriverTrackingTelemetryBox();
    _invalidateUserDataProviders();
  }

  Future<void> signOut({bool allDevices = false}) async {
    final storage = ref.read(_sessionStorageProvider);
    final secureStorage = ref.read(secureTokenStorageProvider);
    final authRepo = ref.read(authRepositoryProvider) as NestjsAuthRepository;

    final refreshToken = await secureStorage.readRefreshToken();

    state = const AppSessionState(session: null, isLoading: false);
    await storage.clear();
    await DriverProfileStorage().clear();
    // Limpa o buffer de telemetria independentemente do estado da rota;
    // evita que pontos de GPS fiquem congelados no disco entre contas.
    await clearDriverTrackingTelemetryBox();
    _invalidateUserDataProviders();

    try {
      await authRepo.logout(refreshToken: refreshToken, allDevices: allDevices);
    } catch (_) {
      // Local cleanup is the source of truth; remote logout is best-effort.
    }
  }

  /// Derruba todo provider que guarda dados do usuário logado (APP-07):
  /// sem isso, providers keepAlive/non-autoDispose sobrevivem ao logout e
  /// vazam PII (filhos, embarques, perfil) para a próxima conta que entrar
  /// no mesmo aparelho. Após a invalidação, cada provider é recriado limpo
  /// no próximo watch.
  ///
  /// `driverTrackingControllerProvider` NÃO entra aqui de propósito: ele já
  /// reage à sessão nula via `syncSession` (para o tracking da rota), e
  /// invalidá-lo recriaria o notifier sem o `initialize()` — quebrando o
  /// tracking do próximo login.
  void _invalidateUserDataProviders() {
    // Portal do responsável.
    ref.invalidate(childrenControllerProvider);
    ref.invalidate(enrollmentsControllerProvider);
    ref.invalidate(parentChildrenProvider);
    ref.invalidate(parentRoutesProvider);
    ref.invalidate(parentBoardingsProvider);
    ref.invalidate(parentUserProfileProvider);

    // Portal do motorista.
    ref.invalidate(driverProfileProvider);
    ref.invalidate(driverProfileSessionGuardProvider);
    ref.invalidate(driverDashboardControllerProvider);
    ref.invalidate(driverRouteControllerProvider);
    ref.invalidate(driverEnrollmentsControllerProvider);
    // Lookup de criança pelo código (UUID): guarda dados da criança pesquisada.
    ref.invalidate(driverLookupControllerProvider);
    ref.invalidate(driverRoutesProvider);
    ref.invalidate(driverProfileChangeRequestsProvider);

    // Notificações e anúncios (conteúdo por usuário/papel).
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationsCountProvider);
    ref.invalidate(adsProvider);
  }
}
