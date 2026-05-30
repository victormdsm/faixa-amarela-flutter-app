import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_session.dart';
import 'app_session_state.dart';

final appSessionControllerProvider =
    NotifierProvider<AppSessionController, AppSessionState>(
      AppSessionController.new,
    );

class AppSessionController extends Notifier<AppSessionState> {
  @override
  AppSessionState build() => const AppSessionState();

  void setSession(AuthSession session) {
    state = state.copyWith(session: session, isLoading: false);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void clear() {
    state = state.copyWith(clearSession: true, isLoading: false);
  }
}
