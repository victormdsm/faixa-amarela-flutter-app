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

  factory DriverProfileDto.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final van = _map(_value(json, 'van', 'van'));

    // Novo contrato NestJS: coverage { schools: number[], districts: number[], shifts: number[] }
    final coverage = _map(_value(json, 'coverage', 'coverage'));
    final coverageSchools = _toIntList(coverage['schools']);
    final coverageDistricts = _toIntList(coverage['districts']);
    final coverageShifts = _toIntList(coverage['shifts']);

    // Fallback para contrato antigo (campos planos e listas de maps)
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
                'shift_ids': coverageShifts.toList(),
              },
            )
            .toList();

    return DriverProfileDto(
      id: _toInt(json['id']),
      userId: _toInt(_value(json, 'user_id', 'userId')),
      name: (json['name'] ?? '').toString(),
      cpf: (json['cpf'] ?? '').toString(),
      licenseNumber: (_value(json, 'cnh', 'cnh') ??
              _value(json, 'license_number', 'licenseNumber') ??
              '')
          .toString(),
      vanId: van.isNotEmpty
          ? _toInt(van['id'])
          : _toInt(_value(json, 'van_id', 'vanId')),
      vanPlate: van.isNotEmpty
          ? (van['plate'] ?? _value(json, 'van_plate', 'vanPlate') ?? '')
              .toString()
          : (_value(json, 'van_plate', 'vanPlate') ?? '').toString(),
      vanModel: van.isNotEmpty
          ? (van['model'] ?? _value(json, 'van_model', 'vanModel') ?? '')
              .toString()
          : (_value(json, 'van_model', 'vanModel') ?? '').toString(),
      vanColor: van.isNotEmpty
          ? van['color']?.toString()
          : _value(json, 'van_color', 'vanColor')?.toString(),
      vanYear: van.isNotEmpty
          ? (van['year'] ?? _value(json, 'van_year', 'vanYear') ?? '')
              .toString()
          : (_value(json, 'van_year', 'vanYear') ?? '').toString(),
      vanImageUrl: van.isNotEmpty
          ? van['imageUrl']?.toString() ?? van['image_url']?.toString()
          : _value(json, 'van_image_url', 'vanImageUrl')?.toString(),
      coverageArea: (_value(json, 'coverage_area', 'coverageArea') ?? '')
          .toString(),
      isActive:
          _value(json, 'is_active', 'isActive') == true ||
          _value(json, 'is_active', 'isActive') == 1,
      cellPhone: _value(json, 'cell_phone', 'cellPhone')?.toString(),
      information: _value(json, 'information', 'information')?.toString(),
      email: _value(json, 'email', 'email')?.toString(),
      avatarUrl: _value(json, 'avatar_url', 'avatarUrl')?.toString(),
      schools: schools,
      districts: districts,
      coverageChangeRequest:
          _value(json, 'coverage_change_request', 'coverageChangeRequest')
              is Map
          ? Map<String, dynamic>.from(
              _value(json, 'coverage_change_request', 'coverageChangeRequest')
                  as Map,
            )
          : null,
      coverageChangeRequestsRecent: _listOfMaps(
        _value(
          json,
          'coverage_change_requests_recent',
          'coverageChangeRequestsRecent',
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
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
      'coverage_area': coverageArea,
      'is_active': isActive,
      'schools': schools,
      'districts': districts,
      'coverage_change_request': coverageChangeRequest,
      'coverage_change_requests_recent': coverageChangeRequestsRecent,
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

  static List<int> _toIntList(dynamic raw) {
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

Object? _value(Map<String, dynamic> json, String snakeCase, String camelCase) {
  if (json.containsKey(snakeCase)) return json[snakeCase];
  return json[camelCase];
}
