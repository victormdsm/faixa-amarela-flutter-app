class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.cellPhone,
    this.avatar,
    this.primaryDriverId,
    this.isActivated = false,
  });

  final int id;
  final String name;
  final String? email;
  final String role;
  final String? cellPhone;
  final String? avatar;
  final int? primaryDriverId;
  final bool isActivated;

  String get normalizedRole => role.trim().toLowerCase();

  bool get isParent => normalizedRole == 'parent' || normalizedRole == 'user';
  bool get isDriver => normalizedRole == 'driver';
  bool get isAdmin =>
      normalizedRole == 'admin' ||
      normalizedRole == 'administrator' ||
      normalizedRole == 'adm';
  bool get isDriverAppRole => isDriver;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: (json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      role: _extractRole(json),
      cellPhone: (json['cell_phone'] ?? json['cellPhone'])?.toString(),
      avatar: json['avatar']?.toString(),
      primaryDriverId:
          ((json['primary_driver_id'] ?? json['primaryDriverId']) as num?)
              ?.toInt(),
      // Defaults to true for backward compatibility with legacy backends
      // that do not send is_activated.
      isActivated: _extractIsActivated(json),
    );
  }

  static String _extractRole(Map<String, dynamic> json) {
    final direct = json['role']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    final roles = json['roles'];
    if (roles is List && roles.isNotEmpty) {
      return roles.first?.toString() ?? '';
    }
    return '';
  }

  static bool _extractIsActivated(Map<String, dynamic> json) {
    final legacy = json['is_activated'];
    if (legacy == false || legacy == 0) return false;
    if (legacy == true || legacy == 1) return true;
    final modern = json['isActive'];
    if (modern == false || modern == 0) return false;
    if (modern == true || modern == 1) return true;
    return true; // default for backward compatibility
  }
}
