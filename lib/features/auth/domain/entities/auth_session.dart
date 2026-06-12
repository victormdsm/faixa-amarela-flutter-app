import 'auth_user.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.user,
    this.expiresAt,
  });

  final String accessToken;
  final String tokenType;
  final String? expiresAt;
  final AuthUser user;

  String get authorizationHeader => '$tokenType $accessToken';

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    String? resolveExpiresAt() {
      final direct = json['expires_at']?.toString();
      if (direct != null && direct.isNotEmpty) return direct;
      final expiresIn = json['expiresIn'];
      if (expiresIn is num) {
        return DateTime.now()
            .add(Duration(seconds: expiresIn.toInt()))
            .toIso8601String();
      }
      return null;
    }

    return AuthSession(
      accessToken: (json['access_token'] ?? json['accessToken'] ?? '')
          .toString(),
      tokenType: (json['token_type'] ?? json['tokenType'] ?? 'Bearer')
          .toString(),
      expiresAt: resolveExpiresAt(),
      user: AuthUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    );
  }
}
