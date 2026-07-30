class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.cellPhone,
    this.avatarUrl,
  });

  final int id;
  final String name;
  final String email;
  final String? cellPhone;
  final String? avatarUrl;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      cellPhone: json['cellPhone']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (cellPhone != null) 'cellPhone': cellPhone,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
}
