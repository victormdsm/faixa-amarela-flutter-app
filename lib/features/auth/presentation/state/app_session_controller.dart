import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../driver_portal/data/driver_profile_storage.dart';
import '../../data/repositories/nestjs_auth_repository.dart';
import '../../data/session_storage.dart';
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

  void updateCurrentUser({String? name, String? cellPhone, String? avatarUrl}) {
    final current = state.session;
    if (current == null) return;

    final updatedUser = current.user.copyWith(
      name: name,
      cellPhone: cellPhone,
      avatar: avatarUrl,
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
  }

  Future<void> signOut({bool allDevices = false}) async {
    final storage = ref.read(_sessionStorageProvider);
    final secureStorage = ref.read(secureTokenStorageProvider);
    final authRepo = ref.read(authRepositoryProvider) as NestjsAuthRepository;

    final refreshToken = await secureStorage.readRefreshToken();

    state = const AppSessionState(session: null, isLoading: false);
    await storage.clear();
    await DriverProfileStorage().clear();

    try {
      await authRepo.logout(refreshToken: refreshToken, allDevices: allDevices);
    } catch (_) {
      // Local cleanup is the source of truth; remote logout is best-effort.
    }
  }
}
