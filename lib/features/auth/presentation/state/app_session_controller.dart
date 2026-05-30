import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/session_storage.dart';
import '../../domain/entities/auth_session.dart';
import 'app_session_state.dart';

final _sessionStorageProvider = Provider<SessionStorage>(
  (_) => SessionStorage(),
);

final appSessionControllerProvider =
    NotifierProvider<AppSessionController, AppSessionState>(
      AppSessionController.new,
    );

class AppSessionController extends Notifier<AppSessionState> {
  @override
  AppSessionState build() {
    final stored = ref.read(_sessionStorageProvider).load();
    return AppSessionState(session: stored);
  }

  void setSession(AuthSession session) {
    state = state.copyWith(session: session, isLoading: false);
    unawaited(ref.read(_sessionStorageProvider).save(session));
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void clear() {
    state = state.copyWith(clearSession: true, isLoading: false);
    unawaited(ref.read(_sessionStorageProvider).clear());
  }
}
