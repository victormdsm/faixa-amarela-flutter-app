import 'package:hive_flutter/hive_flutter.dart';

/// Armazena o perfil do motorista localmente no Hive para exibição imediata.
///
/// O cache é mantido enquanto a sessão for válida; o provider de perfil
/// atualiza esse cache a cada consulta bem-sucedida à API.
class DriverProfileStorage {
  DriverProfileStorage({Box<dynamic>? box}) : _boxOverride = box;

  static const _boxName = 'driver_profile_cache';
  static const _profileKey = 'profile';

  final Box<dynamic>? _boxOverride;

  static Future<void> openBox() => Hive.openBox<dynamic>(_boxName);

  Box<dynamic> get _box => _boxOverride ?? Hive.box<dynamic>(_boxName);

  /// Retorna o perfil cacheado, ou null se não houver cache ou ele for inválido.
  Map<String, dynamic>? load() {
    try {
      final raw = _box.get(_profileKey);
      if (raw is Map) {
        final json = Map<String, dynamic>.from(raw);
        if (json['id'] != null || json['userId'] != null) {
          return json;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Persiste o perfil serializado no cache.
  Future<void> save(Map<String, dynamic> profile) async {
    try {
      await _box.put(_profileKey, profile);
    } catch (_) {}
  }

  /// Remove o cache. Útil no logout ou quando o usuário muda de conta.
  Future<void> clear() async {
    try {
      await _box.delete(_profileKey);
    } catch (_) {}
  }
}
