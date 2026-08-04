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
    this.publicContactName,
    this.publicContactPhone,
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
    this.districtShiftMap = const {},
    this.schoolShiftMap = const {},
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
  final String? publicContactName;
  final String? publicContactPhone;
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

  /// Mapa real bairro→turnos vindo de `coverage.districtShiftMap` (APP-02).
  /// Vazio quando o backend não o envia.
  final Map<int, List<int>> districtShiftMap;

  /// Mapa real escola→turnos vindo de `coverage.schoolShiftMap` (contrato
  /// novo — turnos são definidos pela escola via `schools_has_shifts` e são
  /// apenas informativos para o motorista). Vazio quando o backend não o
  /// envia.
  final Map<int, List<int>> schoolShiftMap;

  factory DriverProfileDto.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final van = _map(json['van']);

    // Contrato NestJS: coverage { schools: number[], districts: number[],
    // shifts: number[], schoolShiftMap: {...} } — o legado districtShiftMap
    // segue tolerado enquanto o backend convive com os dois formatos.
    final coverage = _map(json['coverage']);
    final coverageSchools = toIntList(coverage['schools']);
    final coverageDistricts = toIntList(coverage['districts']);
    final districtShiftMap = _toShiftMap(coverage['districtShiftMap']);
    final schoolShiftMap = _toShiftMap(coverage['schoolShiftMap']);

    // Fallback para listas de maps em camelCase (ex.: cache ou contratos antigos).
    final legacySchools = _listOfMaps(json['schools']);
    final legacyDistricts = _listOfMaps(json['districts']);

    final schools = legacySchools.isNotEmpty
        ? legacySchools
        : coverageSchools
            .map(
              (id) => <String, dynamic>{
                'id': id,
                // Turnos vêm da escola (schools_has_shifts) via
                // coverage.schoolShiftMap — informativos, não editáveis.
                'shiftIds': schoolShiftMap[id] ?? const <int>[],
              },
            )
            .toList();

    final districts = legacyDistricts.isNotEmpty
        ? legacyDistricts
        : coverageDistricts
            .map(
              (id) => <String, dynamic>{
                'id': id,
                // APP-02: usa o mapa real bairro→turnos exposto pelo backend.
                // Sem ele, o bairro fica sem turnos marcados — nada de
                // fabricar a união global de turnos replicada por bairro.
                'shiftIds': districtShiftMap[id] ?? const <int>[],
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
      publicContactName: (van['publicContactName'] ?? van['public_contact_name'])?.toString(),
      publicContactPhone: (van['publicContactPhone'] ?? van['public_contact_phone'])?.toString(),
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
      districtShiftMap: districtShiftMap,
      schoolShiftMap: schoolShiftMap,
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
        'publicContactName': publicContactName,
        'publicContactPhone': publicContactPhone,
      },
      'coverageArea': coverageArea,
      'isActive': isActive,
      'status': status,
      'cnhCategory': cnhCategory,
      'schools': schools,
      'districts': districts,
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
      publicContactName: publicContactName,
      publicContactPhone: publicContactPhone,
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
      publicContactName: profile.publicContactName,
      publicContactPhone: profile.publicContactPhone,
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
      districtShiftMap: {
        for (final district in profile.districts)
          if (((district['id'] as num?)?.toInt() ?? 0) > 0)
            (district['id'] as num).toInt(): toIntList(district['shiftIds']),
      },
      schoolShiftMap: {
        for (final school in profile.schools)
          if (((school['id'] as num?)?.toInt() ?? 0) > 0)
            (school['id'] as num).toInt(): toIntList(school['shiftIds']),
      },
    );
  }

  static List<Map<String, dynamic>> _listOfMaps(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  /// Converte um mapa id→turnos do contrato (`coverage.districtShiftMap`
  /// legado ou `coverage.schoolShiftMap`) para `{id: [shiftIds]}`.
  /// Tolera as duas serializações: objeto `{"10": [1, 2]}` e lista
  /// `[{districtId|schoolId: 10, shiftIds: [1, 2]}]` (a forma que o app
  /// envia no submit de solicitação de alteração).
  static Map<int, List<int>> _toShiftMap(dynamic raw) {
    final result = <int, List<int>>{};

    int toId(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    if (raw is Map) {
      for (final entry in raw.entries) {
        final id = toId(entry.key);
        if (id <= 0) continue;
        result[id] = toIntList(entry.value);
      }
    } else if (raw is List) {
      for (final item in raw.whereType<Map>()) {
        final id = toId(
          item['districtId'] ??
              item['district_id'] ??
              item['schoolId'] ??
              item['school_id'] ??
              item['id'],
        );
        if (id <= 0) continue;
        result[id] = toIntList(
          item['shiftIds'] ?? item['shift_ids'] ?? item['shifts'],
        );
      }
    }
    return result;
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

