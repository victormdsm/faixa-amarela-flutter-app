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

  bool get isParent => normalizedRole == 'parent';
  bool get isDriver => normalizedRole == 'driver';
  bool get isAdmin =>
      normalizedRole == 'admin' ||
      normalizedRole == 'administrator' ||
      normalizedRole == 'adm';
  bool get isDriverAppRole => isDriver;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      role: (json['role'] ?? '').toString(),
      cellPhone: json['cell_phone']?.toString(),
      avatar: json['avatar']?.toString(),
      primaryDriverId: (json['primary_driver_id'] as num?)?.toInt(),
      isActivated: json['is_activated'] == true || json['is_activated'] == 1,
    );
  }
}
