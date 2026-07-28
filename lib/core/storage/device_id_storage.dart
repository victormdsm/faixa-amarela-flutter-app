import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Armazena um identificador estável e anônimo do dispositivo, usado na
/// medição de anúncios (impressões/cliques). Gerado uma única vez (UUID v4)
/// e persistido no secure storage; falhas de plataforma caem num id volátil
/// em memória para nunca quebrar o fluxo.
class DeviceIdStorage {
  DeviceIdStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ?? const FlutterSecureStorage(aOptions: AndroidOptions());

  final FlutterSecureStorage _storage;

  static const _deviceIdKey = 'ads_device_id';

  String? _cached;

  Future<String> getOrCreate() async {
    final cached = _cached;
    if (cached != null) return cached;

    try {
      final existing = await _storage.read(key: _deviceIdKey);
      if (existing != null && existing.isNotEmpty) {
        _cached = existing;
        return existing;
      }
      final created = _generateUuidV4();
      await _storage.write(key: _deviceIdKey, value: created);
      _cached = created;
      return created;
    } catch (_) {
      // Secure storage indisponível (ex.: testes, plataforma sem plugin):
      // mantém um id apenas em memória nesta sessão.
      return _cached ??= _generateUuidV4();
    }
  }

  static String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant RFC 4122
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
