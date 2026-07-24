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
    this.status,
    this.cnhCategory,
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
  final String? status;
  final String? cnhCategory;
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
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      cpf: (json['cpf'] ?? '').toString(),
      licenseNumber: (json['licenseNumber'] ?? '').toString(),
      vanId: van.isNotEmpty
          ? (van['id'] as num?)?.toInt() ?? (json['vanId'] as num?)?.toInt() ?? 0
          : (json['vanId'] as num?)?.toInt() ?? 0,
      vanPlate: van.isNotEmpty
          ? (van['plate'] ?? json['vanPlate'] ?? '').toString()
          : (json['vanPlate'] ?? '').toString(),
      vanModel: van.isNotEmpty
          ? (van['model'] ?? json['vanModel'] ?? '').toString()
          : (json['vanModel'] ?? '').toString(),
      vanColor: van.isNotEmpty
          ? van['color']?.toString()
          : json['vanColor']?.toString(),
      vanYear: van.isNotEmpty
          ? (van['year'] ?? json['vanYear'] ?? '').toString()
          : (json['vanYear'] ?? '').toString(),
      vanImageUrl: van.isNotEmpty
          ? van['imageUrl']?.toString()
          : json['vanImageUrl']?.toString(),
      coverageArea: (json['coverageArea'] ?? '').toString(),
      isActive: json['isActive'] == true || json['isActive'] == 1,
      status: json['status']?.toString(),
      cnhCategory: json['cnhCategory']?.toString(),
      cellPhone: json['cellPhone']?.toString(),
      information: json['information']?.toString(),
      email: json['email']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      schools: _listOfMaps(json['schools']),
      districts: _listOfMaps(json['districts']),
      coverageChangeRequest: json['coverageChangeRequest'] is Map
          ? Map<String, dynamic>.from(json['coverageChangeRequest'] as Map)
          : null,
      coverageChangeRequestsRecent: _listOfMaps(
        json['coverageChangeRequestsRecent'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'cpf': cpf,
      'licenseNumber': licenseNumber,
      'cnh': licenseNumber,
      'cellPhone': cellPhone,
      'information': information,
      'email': email,
      'avatarUrl': avatarUrl,
      'van': <String, dynamic>{
        'id': vanId,
        'plate': vanPlate,
        'model': vanModel,
        'color': vanColor,
        'year': vanYear,
        'imageUrl': vanImageUrl,
      },
      'coverageArea': coverageArea,
      'isActive': isActive,
      'status': status,
      'cnhCategory': cnhCategory,
      'schools': schools,
      'districts': districts,
      'coverageChangeRequest': coverageChangeRequest,
      'coverageChangeRequestsRecent': coverageChangeRequestsRecent,
    };
  }

  static List<Map<String, dynamic>> _listOfMaps(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
}
