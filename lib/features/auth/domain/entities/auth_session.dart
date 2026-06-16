import 'auth_user.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.user,
    this.refreshToken,
    this.expiresAt,
    this.refreshExpiresAt,
  });

  final String accessToken;
  final String tokenType;
  final String? refreshToken;
  final String? expiresAt;
  final String? refreshExpiresAt;
  final AuthUser user;

  String get authorizationHeader => '$tokenType $accessToken';

  bool get hasRefreshToken => refreshToken != null && refreshToken!.isNotEmpty;

  bool get isAccessExpired {
    final expiresAt = this.expiresAt;
    if (expiresAt == null || expiresAt.isEmpty) return false;
    final expiry = DateTime.tryParse(expiresAt);
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 30)));
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    String? resolveExpiresAt(String key) {
      final direct = json['${key}_at']?.toString();
      if (direct != null && direct.isNotEmpty) return direct;
      final durationKeys = key == 'expires'
          ? ['expiresIn', 'expires_in']
          : ['refreshExpiresIn', 'refresh_expires_in'];
      final expiresIn = durationKeys
          .map((k) => json[k])
          .firstWhere((v) => v is num, orElse: () => null);
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
      refreshToken: (json['refresh_token'] ?? json['refreshToken'])?.toString(),
      tokenType: (json['token_type'] ?? json['tokenType'] ?? 'Bearer')
          .toString(),
      expiresAt: resolveExpiresAt('expires'),
      refreshExpiresAt: resolveExpiresAt('refreshExpires'),
      user: AuthUser.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
      ),
    );
  }
}
