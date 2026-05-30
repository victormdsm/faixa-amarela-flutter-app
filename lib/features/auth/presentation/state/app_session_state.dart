import '../../domain/entities/auth_session.dart';

class AppSessionState {
  const AppSessionState({this.session, this.isLoading = false});

  final AuthSession? session;
  final bool isLoading;

  bool get isAuthenticated => session != null;

  AppSessionState copyWith({
    AuthSession? session,
    bool? isLoading,
    bool clearSession = false,
  }) {
    return AppSessionState(
      session: clearSession ? null : (session ?? this.session),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
