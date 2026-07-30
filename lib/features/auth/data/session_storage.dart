import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/secure_token_storage.dart';
import '../domain/entities/auth_session.dart';
import '../domain/entities/auth_user.dart';
import '../domain/entities/user_role.dart';

/// Armazena metadados não sensíveis do usuário no Hive para startup rápido.
/// Access token e refresh token ficam exclusivamente em [SecureTokenStorage].
class SessionStorage {
  SessionStorage({required SecureTokenStorage secureStorage, Box<dynamic>? box})
    : _secureStorage = secureStorage,
      _boxOverride = box;

  final SecureTokenStorage _secureStorage;
  final Box<dynamic>? _boxOverride;

  static const _boxName = 'auth_session';

  static const _kUserId = 'user_id';
  static const _kUserName = 'user_name';
  static const _kUserEmail = 'user_email';
  static const _kUserRoles = 'user_roles';
  static const _kUserIsActivated = 'user_is_activated';
  static const _kTokenType = 'token_type';
  static const _kExpiresAt = 'expires_at';
  // Qual endpoint de login foi usado (driver | parent). Fonte de verdade
  // para roteamento quando o usuário possui múltiplos roles.
  static const _kLoginRole = 'login_role';

  static Future<void> openBox() => Hive.openBox<dynamic>(_boxName);

  Box<dynamic> get _box => _boxOverride ?? Hive.box<dynamic>(_boxName);

  /// Carrega sessão de forma assíncrona. O token é lido do secure storage;
  /// metadados do usuário vêm do Hive.
  Future<AuthSession?> load() async {
    try {
      final token = await _secureStorage.readAccessToken();
      final refreshToken = await _secureStorage.readRefreshToken();
      final tokenType = (_box.get(_kTokenType) as String?) ?? 'Bearer';
      final rawUserId = _box.get(_kUserId);
      final userName = _box.get(_kUserName) as String?;
      final userRoles = _extractStoredRoles(_box.get(_kUserRoles));

      if (token == null ||
          token.isEmpty ||
          rawUserId == null ||
          userRoles.isEmpty) {
        return null;
      }

      final userId = rawUserId is num
          ? rawUserId.toInt()
          : int.tryParse(rawUserId.toString());
      if (userId == null) {
        return null;
      }

      final user = AuthUser(
        id: userId,
        name: userName ?? '',
        email: _box.get(_kUserEmail) as String?,
        roles: userRoles,
        isActivated: _box.get(_kUserIsActivated) as bool? ?? true,
      );

      return AuthSession(
        accessToken: token,
        refreshToken: refreshToken,
        tokenType: tokenType,
        user: user,
        expiresAt: _box.get(_kExpiresAt) as String?,
      );
    } catch (_) {
      return null;
    }
  }

  /// Carrega o role usado no último login bem-sucedido.
  /// Retorna null se nunca foi persistido (sessões antigas).
  UserRole? loadLoginRole() {
    final stored = _box.get(_kLoginRole) as String?;
    return switch (stored) {
      'driver' => UserRole.driver,
      'parent' => UserRole.parent,
      _ => null,
    };
  }

  Future<void> save(AuthSession session, {UserRole? loginRole}) async {
    await _secureStorage.writeAccessToken(session.accessToken);
    if (session.hasRefreshToken) {
      await _secureStorage.writeRefreshToken(session.refreshToken!);
    }
    final data = <String, dynamic>{
      _kUserId: session.user.id,
      _kUserName: session.user.name,
      _kUserEmail: session.user.email,
      _kUserRoles: session.user.roles,
      _kUserIsActivated: session.user.isActivated,
      _kTokenType: session.tokenType,
      _kExpiresAt: session.expiresAt,
    };
    if (loginRole != null) {
      data[_kLoginRole] = loginRole == UserRole.driver ? 'driver' : 'parent';
    }
    await _box.putAll(data);
  }

  static List<String> _extractStoredRoles(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e?.toString().trim())
          .where((r) => r != null && r.isNotEmpty)
          .cast<String>()
          .toList(growable: false);
    }
    // Migração legada: o campo antigo armazenava uma String única.
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    return const [];
  }

  Future<void> clear() async {
    await _secureStorage.clearAll();
    await _box.clear();
  }
}
