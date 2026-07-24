import '../../domain/models/driver_profile.dart';

class DriverProfileDto {
  const DriverProfileDto({
    required this.id,
    required this.userId,
    required this.name,
    required this.cpf,
    required this.licenseNumber,
    required this.vanId,
    required this.vanPlate,
    required this.vanModel,
    required this.vanYear,
    required this.vanColor,
    required this.vanImageUrl,
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

  factory DriverProfileDto.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final van = _map(json['van']);

    // Novo contrato NestJS: coverage { schools: number[], districts: number[], shifts: number[] }
    final coverage = _map(json['coverage']);
    final coverageSchools = toIntList(coverage['schools']);
    final coverageDistricts = toIntList(coverage['districts']);
    final coverageShifts = toIntList(coverage['shifts']);

    // Fallback para listas de maps em camelCase (ex.: cache ou contratos antigos).
    final legacySchools = _listOfMaps(json['schools']);
    final legacyDistricts = _listOfMaps(json['districts']);

    final schools = legacySchools.isNotEmpty
        ? legacySchools
        : coverageSchools.map((id) => <String, dynamic>{'id': id}).toList();

    final districts = legacyDistricts.isNotEmpty
        ? legacyDistricts
        : coverageDistricts
            .map(
              (id) => <String, dynamic>{
                'id': id,
                // O NestJS retorna turnos globalmente; replicamos em cada
                // bairro para manter a UI funcional ate haver mapeamento
                // district->turnos no contrato.
                'shiftIds': coverageShifts.toList(),
              },
            )
            .toList();

    // O contrato NestJS aninha o veiculo em `van`; campos planos sao
    // mantidos apenas para compatibilidade com payloads ja serializados.
    final int effectiveVanId;
    final String effectiveVanPlate;
    final String effectiveVanModel;
    final String? effectiveVanColor;
    final String effectiveVanYear;
    final String? effectiveVanImageUrl;

    if (van.isNotEmpty) {
      effectiveVanId = toInt(van['id']);
      effectiveVanPlate = (van['plate'] ?? '').toString();
      effectiveVanModel = (van['model'] ?? '').toString();
      effectiveVanColor = van['color']?.toString();
      effectiveVanYear = (van['year'] ?? '').toString();
      effectiveVanImageUrl = van['imageUrl']?.toString();
    } else {
      effectiveVanId = toInt(json['vanId']);
      effectiveVanPlate = (json['vanPlate'] ?? '').toString();
      effectiveVanModel = (json['vanModel'] ?? '').toString();
      effectiveVanColor = json['vanColor']?.toString();
      effectiveVanYear = (json['vanYear'] ?? '').toString();
      effectiveVanImageUrl = json['vanImageUrl']?.toString();
    }

    return DriverProfileDto(
      id: toInt(json['id']),
      userId: toInt(json['userId']),
      name: (json['name'] ?? '').toString(),
      cpf: (json['cpf'] ?? '').toString(),
      licenseNumber:
          (json['cnh'] ?? json['licenseNumber'] ?? '').toString(),
      vanId: effectiveVanId,
      vanPlate: effectiveVanPlate,
      vanModel: effectiveVanModel,
      vanColor: effectiveVanColor,
      vanYear: effectiveVanYear,
      vanImageUrl: effectiveVanImageUrl,
      coverageArea: (json['coverageArea'] ?? '').toString(),
      isActive: json['isActive'] == true || json['isActive'] == 1,
      status: json['status']?.toString(),
      cnhCategory: json['cnhCategory']?.toString(),
      cellPhone: json['cellPhone']?.toString(),
      information: json['information']?.toString(),
      email: json['email']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      schools: schools,
      districts: districts,
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

  DriverProfile toDomain() {
    return DriverProfile(
      id: id,
      userId: userId,
      name: name,
      cpf: cpf,
      licenseNumber: licenseNumber,
      vanId: vanId,
      vanPlate: vanPlate,
      vanModel: vanModel,
      vanColor: vanColor,
      vanYear: vanYear,
      vanImageUrl: vanImageUrl,
      coverageArea: coverageArea,
      isActive: isActive,
      status: status,
      cnhCategory: cnhCategory,
      cellPhone: cellPhone,
      information: information,
      email: email,
      avatarUrl: avatarUrl,
      schools: schools,
      districts: districts,
      coverageChangeRequest: coverageChangeRequest,
      coverageChangeRequestsRecent: coverageChangeRequestsRecent,
    );
  }

  factory DriverProfileDto.fromDomain(DriverProfile profile) {
    return DriverProfileDto(
      id: profile.id,
      userId: profile.userId,
      name: profile.name,
      cpf: profile.cpf,
      licenseNumber: profile.licenseNumber,
      vanId: profile.vanId,
      vanPlate: profile.vanPlate,
      vanModel: profile.vanModel,
      vanColor: profile.vanColor,
      vanYear: profile.vanYear,
      vanImageUrl: profile.vanImageUrl,
      coverageArea: profile.coverageArea,
      isActive: profile.isActive,
      status: profile.status,
      cnhCategory: profile.cnhCategory,
      cellPhone: profile.cellPhone,
      information: profile.information,
      email: profile.email,
      avatarUrl: profile.avatarUrl,
      schools: profile.schools,
      districts: profile.districts,
      coverageChangeRequest: profile.coverageChangeRequest,
      coverageChangeRequestsRecent: profile.coverageChangeRequestsRecent,
    );
  }

  static List<Map<String, dynamic>> _listOfMaps(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  static Map<String, dynamic> _map(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const <String, dynamic>{};
  }

  static List<int> toIntList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) {
          if (e is num) return e.toInt();
          if (e is String) return int.tryParse(e);
          return null;
        })
        .whereType<int>()
        .toList();
  }
}

