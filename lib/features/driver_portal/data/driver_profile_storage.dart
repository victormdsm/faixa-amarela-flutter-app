import 'package:hive_flutter/hive_flutter.dart';

/// Armazena o perfil do motorista localmente no Hive para exibição imediata.
///
/// O cache é indexado por `userId` (chave `profile_<userId>`) para que contas
/// diferentes no mesmo aparelho nunca vejam o perfil uma da outra. Ele é
/// atualizado a cada consulta bem-sucedida à API e removido no logout/troca
/// de conta ([AppSessionController.clear]/[signOut]).
///
/// Não há expiração nem sync automático: quem decide quando buscar dados
/// frescos é o [DriverProfileController] (primeira abertura sem cache, botão
/// de sincronizar ou push de aprovação).
class DriverProfileStorage {
  DriverProfileStorage({Box<dynamic>? box}) : _boxOverride = box;

  static const _boxName = 'driver_profile_cache';
  static const _keyPrefix = 'profile_';

  /// Chave legada (cache único sem userId), removida no [clear] para não
  /// deixar lixo de versões antigas no box.
  static const _legacyKey = 'profile';

  final Box<dynamic>? _boxOverride;

  static Future<void> openBox() => Hive.openBox<dynamic>(_boxName);

  Box<dynamic> get _box => _boxOverride ?? Hive.box<dynamic>(_boxName);

  static String _keyFor(int userId) => '$_keyPrefix$userId';

  /// Retorna o perfil cacheado do usuário, ou null se não houver cache ou
  /// ele for inválido.
  Map<String, dynamic>? load(int userId) {
    try {
      final raw = _box.get(_keyFor(userId));
      if (raw is Map) {
        final json = Map<String, dynamic>.from(raw);
        if (json['id'] != null || json['userId'] != null) {
          return json;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Persiste o perfil serializado no cache do usuário.
  Future<void> save(int userId, Map<String, dynamic> profile) async {
    try {
      await _box.put(_keyFor(userId), profile);
    } catch (_) {}
  }

  /// Remove todos os perfis cacheados (inclui a chave legada). Usado no
  /// logout ou quando o usuário muda de conta.
  Future<void> clear() async {
    try {
      final keys = _box.keys
          .where((k) => k.toString().startsWith(_keyPrefix))
          .toList(growable: false);
      await _box.deleteAll([...keys, _legacyKey]);
    } catch (_) {}
  }
}
