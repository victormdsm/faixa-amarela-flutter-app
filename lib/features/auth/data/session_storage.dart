import 'package:hive_flutter/hive_flutter.dart';

import '../domain/entities/auth_session.dart';
import '../domain/entities/auth_user.dart';

class SessionStorage {
  static const _boxName = 'auth_session';

  static const _kToken = 'access_token';
  static const _kTokenType = 'token_type';
  static const _kExpiresAt = 'expires_at';
  static const _kUserId = 'user_id';
  static const _kUserName = 'user_name';
  static const _kUserEmail = 'user_email';
  static const _kUserRole = 'user_role';
  static const _kUserCellPhone = 'user_cell_phone';
  static const _kUserAvatar = 'user_avatar';
  static const _kUserPrimaryDriverId = 'user_primary_driver_id';
  static const _kUserIsActivated = 'user_is_activated';

  static Future<void> openBox() => Hive.openBox<dynamic>(_boxName);

  Box<dynamic> get _box => Hive.box<dynamic>(_boxName);

  AuthSession? load() {
    try {
      final token = _box.get(_kToken) as String?;
      final tokenType = _box.get(_kTokenType) as String?;
      final userId = _box.get(_kUserId);
      final userName = _box.get(_kUserName) as String?;
      final userRole = _box.get(_kUserRole) as String?;

      if (token == null || token.isEmpty || userId == null || userRole == null) {
        return null;
      }

      final user = AuthUser(
        id: (userId as num).toInt(),
        name: userName ?? '',
        email: _box.get(_kUserEmail) as String?,
        role: userRole,
        cellPhone: _box.get(_kUserCellPhone) as String?,
        avatar: _box.get(_kUserAvatar) as String?,
        primaryDriverId: (_box.get(_kUserPrimaryDriverId) as num?)?.toInt(),
        isActivated: _box.get(_kUserIsActivated) as bool? ?? false,
      );

      return AuthSession(
        accessToken: token,
        tokenType: tokenType ?? 'Bearer',
        user: user,
        expiresAt: _box.get(_kExpiresAt) as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(AuthSession session) async {
    await _box.putAll(<String, dynamic>{
      _kToken: session.accessToken,
      _kTokenType: session.tokenType,
      _kExpiresAt: session.expiresAt,
      _kUserId: session.user.id,
      _kUserName: session.user.name,
      _kUserEmail: session.user.email,
      _kUserRole: session.user.role,
      _kUserCellPhone: session.user.cellPhone,
      _kUserAvatar: session.user.avatar,
      _kUserPrimaryDriverId: session.user.primaryDriverId,
      _kUserIsActivated: session.user.isActivated,
    });
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
