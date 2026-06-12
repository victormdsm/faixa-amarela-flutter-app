/// Utilities for masking and redacting sensitive data.
/// Never expose full CPF, email, or phone in UI, logs, or errors.
abstract final class Masking {
  static String cpf(String? value) {
    if (value == null || value.length < 4) return '***';
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (clean.length != 11) return '***';
    return '***.***.${clean.substring(6, 9)}-${clean.substring(9, 11)}';
  }

  static String cpfLastDigits(String? value, {int digits = 3}) {
    if (value == null || value.isEmpty) return '***';
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (clean.length <= digits) return '***';
    return '***-${clean.substring(clean.length - digits)}';
  }

  static String email(String? value) {
    if (value == null || !value.contains('@')) return '***';
    final parts = value.split('@');
    final local = parts.first;
    final domain = parts.last;
    String maskedLocal;
    if (local.length <= 2) {
      maskedLocal = '*' * local.length;
    } else {
      maskedLocal =
          '${local[0]}${'*' * (local.length - 2)}${local[local.length - 1]}';
    }
    return '$maskedLocal@$domain';
  }

  static String phone(String? value) {
    if (value == null || value.isEmpty) return '***';
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 4) return '***';
    return '${'*' * (clean.length - 4)}${clean.substring(clean.length - 4)}';
  }

  static String token(String? value) {
    if (value == null || value.isEmpty) return '***';
    if (value.length <= 8) return '*' * value.length;
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }

  static Map<String, dynamic> redactJson(Map<String, dynamic> json) {
    final sensitiveKeys = <String>{
      'cpf',
      'password',
      'password_confirmation',
      'access_token',
      'token',
      'refresh_token',
      'email',
      'cell_phone',
      'phone',
      'location',
      'latitude',
      'longitude',
    };
    return json.map((key, value) {
      if (sensitiveKeys.contains(key.toLowerCase())) {
        if (key.toLowerCase() == 'cpf') {
          return MapEntry(key, cpfLastDigits(value?.toString()));
        }
        if (key.toLowerCase().contains('token')) {
          return MapEntry(key, token(value?.toString()));
        }
        if (key.toLowerCase().contains('email')) {
          return MapEntry(key, email(value?.toString()));
        }
        if (key.toLowerCase().contains('phone')) {
          return MapEntry(key, phone(value?.toString()));
        }
        return MapEntry(key, '***');
      }
      if (value is Map<String, dynamic>) {
        return MapEntry(key, redactJson(value));
      }
      if (value is List) {
        return MapEntry(
          key,
          value
              .map((e) => e is Map<String, dynamic> ? redactJson(e) : e)
              .toList(),
        );
      }
      return MapEntry(key, value);
    });
  }
}
