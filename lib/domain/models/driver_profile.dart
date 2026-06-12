class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.cpf,
    required this.licenseNumber,
    required this.vanId,
    required this.vanPlate,
    required this.vanModel,
    this.vanColor,
    required this.vanYear,
    this.vanImageUrl,
    required this.coverageArea,
    this.isActive = true,
    this.cellPhone,
    this.information,
    this.email,
    this.avatarUrl,
    this.schools = const [],
    this.districts = const [],
    this.coverageChangeRequest,
    this.coverageChangeRequestsRecent = const [],
  });

  final int id;
  final int userId;
  final String name;
  final String cpf;
  final String licenseNumber;
  final int vanId;
  final String vanPlate;
  final String vanModel;
  final String? vanColor;
  final String vanYear;
  final String? vanImageUrl;
  final String coverageArea;
  final bool isActive;
  final String? cellPhone;
  final String? information;
  final String? email;
  final String? avatarUrl;
  final List<Map<String, dynamic>> schools;
  final List<Map<String, dynamic>> districts;
  final Map<String, dynamic>? coverageChangeRequest;
  final List<Map<String, dynamic>> coverageChangeRequestsRecent;

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    final van = json['van'] is Map
        ? Map<String, dynamic>.from(json['van'] as Map)
        : const <String, dynamic>{};

    return DriverProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      cpf: (json['cpf'] ?? '').toString(),
      licenseNumber: (json['license_number'] ?? json['cnh'] ?? '').toString(),
      vanId: van.isNotEmpty
          ? (van['id'] as num?)?.toInt() ?? (json['van_id'] as num?)?.toInt() ?? 0
          : (json['van_id'] as num?)?.toInt() ?? 0,
      vanPlate: van.isNotEmpty
          ? (van['plate'] ?? json['van_plate'] ?? '').toString()
          : (json['van_plate'] ?? '').toString(),
      vanModel: van.isNotEmpty
          ? (van['model'] ?? json['van_model'] ?? '').toString()
          : (json['van_model'] ?? '').toString(),
      vanColor: van.isNotEmpty
          ? van['color']?.toString()
          : json['van_color']?.toString(),
      vanYear: van.isNotEmpty
          ? (van['year'] ?? json['van_year'] ?? '').toString()
          : (json['van_year'] ?? '').toString(),
      vanImageUrl: van.isNotEmpty
          ? van['imageUrl']?.toString() ?? van['image_url']?.toString()
          : json['van_image_url']?.toString(),
      coverageArea: (json['coverage_area'] ?? '').toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      cellPhone: json['cell_phone']?.toString(),
      information: json['information']?.toString(),
      email: json['email']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      schools: _listOfMaps(json['schools']),
      districts: _listOfMaps(json['districts']),
      coverageChangeRequest: json['coverage_change_request'] is Map
          ? Map<String, dynamic>.from(json['coverage_change_request'] as Map)
          : null,
      coverageChangeRequestsRecent: _listOfMaps(
        json['coverage_change_requests_recent'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final vehicle = <String, dynamic>{
      'brand': vanModel,
      'color': vanColor ?? '',
      'year': vanYear,
      'license_plate': vanPlate,
      'image_url': vanImageUrl,
    };

    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'cpf': cpf,
      'license_number': licenseNumber,
      'cnh': licenseNumber,
      'cell_phone': cellPhone,
      'information': information,
      'email': email,
      'avatar_url': avatarUrl,
      'van_id': vanId,
      'van_plate': vanPlate,
      'van_model': vanModel,
      'van_color': vanColor,
      'van_year': vanYear,
      'van_image_url': vanImageUrl,
      'vehicle': vehicle,
      'coverage_area': coverageArea,
      'is_active': isActive,
      'schools': schools,
      'districts': districts,
      'coverage_change_request': coverageChangeRequest,
      'coverage_change_requests_recent': coverageChangeRequestsRecent,
    };
  }

  static List<Map<String, dynamic>> _listOfMaps(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
}
