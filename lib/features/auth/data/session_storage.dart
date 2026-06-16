import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/storage/secure_token_storage.dart';
import '../domain/entities/auth_session.dart';
import '../domain/entities/auth_user.dart';

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
  static const _kUserRole = 'user_role';
  static const _kUserCellPhone = 'user_cell_phone';
  static const _kUserAvatar = 'user_avatar';
  static const _kUserPrimaryDriverId = 'user_primary_driver_id';
  static const _kUserIsActivated = 'user_is_activated';
  static const _kTokenType = 'token_type';
  static const _kExpiresAt = 'expires_at';

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
      final userRole = _box.get(_kUserRole) as String?;

      if (token == null ||
          token.isEmpty ||
          rawUserId == null ||
          userRole == null) {
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
        role: userRole,
        cellPhone: _box.get(_kUserCellPhone) as String?,
        avatar: _box.get(_kUserAvatar) as String?,
        primaryDriverId: (_box.get(_kUserPrimaryDriverId) as num?)?.toInt(),
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

  Future<void> save(AuthSession session) async {
    await _secureStorage.writeAccessToken(session.accessToken);
    if (session.hasRefreshToken) {
      await _secureStorage.writeRefreshToken(session.refreshToken!);
    }
    await _box.putAll(<String, dynamic>{
      _kUserId: session.user.id,
      _kUserName: session.user.name,
      _kUserEmail: session.user.email,
      _kUserRole: session.user.role,
      _kUserCellPhone: session.user.cellPhone,
      _kUserAvatar: session.user.avatar,
      _kUserPrimaryDriverId: session.user.primaryDriverId,
      _kUserIsActivated: session.user.isActivated,
      _kTokenType: session.tokenType,
      _kExpiresAt: session.expiresAt,
    });
  }

  Future<void> clear() async {
    await _secureStorage.clearAll();
    await _box.clear();
  }
}
