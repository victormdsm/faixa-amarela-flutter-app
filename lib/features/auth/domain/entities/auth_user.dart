class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    this.cellPhone,
    this.avatar,
    this.primaryDriverId,
    this.isActivated = false,
  });

  final int id;
  final String name;
  final String? email;

  /// Todas as roles retornadas pelo backend. O campo `role` (singular) é
  /// legado e não deve ser usado como fonte de verdade.
  final List<String> roles;
  final String? cellPhone;
  final String? avatar;
  final int? primaryDriverId;
  final bool isActivated;

  /// Primeira role não-vazia da lista, usada apenas para mensagens legadas.
  String get primaryRole => roles.isNotEmpty ? roles.first : '';

  List<String> get _normalizedRoles =>
      roles.map((r) => r.trim().toLowerCase()).toList(growable: false);

  bool _hasRole(String code) => _normalizedRoles.contains(code);

  bool get isParent => _hasRole('parent') || _hasRole('user');
  bool get isDriver => _hasRole('driver');
  bool get isAdmin =>
      _hasRole('admin') || _hasRole('administrator') || _hasRole('adm');
  bool get isDriverAppRole => isDriver;

  AuthUser copyWith({
    int? id,
    String? name,
    String? email,
    List<String>? roles,
    String? cellPhone,
    String? avatar,
    int? primaryDriverId,
    bool? isActivated,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      roles: roles ?? this.roles,
      cellPhone: cellPhone ?? this.cellPhone,
      avatar: avatar ?? this.avatar,
      primaryDriverId: primaryDriverId ?? this.primaryDriverId,
      isActivated: isActivated ?? this.isActivated,
    );
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: (json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      roles: _extractRoles(json),
      cellPhone: json['cellPhone']?.toString(),
      avatar: json['avatar']?.toString(),
      primaryDriverId: (json['primaryDriverId'] as num?)?.toInt(),
      // Defaults to true when the backend does not send isActive.
      isActivated: _extractIsActivated(json),
    );
  }

  static List<String> _extractRoles(Map<String, dynamic> json) {
    final roles = json['roles'];
    if (roles is List && roles.isNotEmpty) {
      final result = <String>[];
      for (final r in roles) {
        final roleText = r?.toString().trim();
        if (roleText != null && roleText.isNotEmpty) {
          result.add(roleText);
        }
      }
      if (result.isNotEmpty) return result;
    }

    // Fallback legado: campo `role` singular (não deve ocorrer no NestJS).
    final direct = json['role']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return [direct];

    throw const FormatException(
      'Usuario sem perfil (roles) identificado pelo servidor.',
    );
  }

  static bool _extractIsActivated(Map<String, dynamic> json) {
    final modern = json['isActive'];
    if (modern == false || modern == 0) return false;
    if (modern == true || modern == 1) return true;
    return true; // default for backward compatibility
  }
}
