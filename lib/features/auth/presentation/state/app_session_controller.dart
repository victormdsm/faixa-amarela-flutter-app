import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/session_storage.dart';
import '../../domain/entities/auth_session.dart';
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
    state = AppSessionState(session: stored, isLoading: false);

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

  void setSession(AuthSession session) {
    state = state.copyWith(session: session, isLoading: false);
    unawaited(ref.read(_sessionStorageProvider).save(session));
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void clear() {
    state = const AppSessionState(session: null, isLoading: false);
    unawaited(ref.read(_sessionStorageProvider).clear());
  }
}
