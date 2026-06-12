import '../../domain/models/child.dart';

class ChildDto {
  const ChildDto({
    required this.id,
    required this.name,
    required this.cpf,
    this.birthDate,
    required this.schoolName,
    required this.shiftId,
    required this.shiftName,
    required this.parentId,
    required this.parentName,
    required this.address,
    this.photoUrl,
    this.isInDebt = false,
    this.createdAt,
  });

  final int id;
  final String name;
  final String cpf;
  final DateTime? birthDate;
  final String schoolName;
  final int shiftId;
  final String shiftName;
  final int parentId;
  final String parentName;
  final ChildAddressDto address;
  final String? photoUrl;
  final bool isInDebt;
  final DateTime? createdAt;

  factory ChildDto.fromJson(Map<String, dynamic> json) {
    return ChildDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      cpf: (json['cpf'] ?? '').toString(),
      birthDate: _value(json, 'birth_date', 'birthDate') != null
          ? DateTime.tryParse(
              _value(json, 'birth_date', 'birthDate').toString(),
            )
          : null,
      schoolName: (_value(json, 'school_name', 'schoolName') ?? '').toString(),
      shiftId: (_value(json, 'shift_id', 'shiftId') as num?)?.toInt() ?? 0,
      shiftName: (_value(json, 'shift_name', 'shiftName') ?? '').toString(),
      parentId: (_value(json, 'parent_id', 'parentId') as num?)?.toInt() ?? 0,
      parentName: (_value(json, 'parent_name', 'parentName') ?? '').toString(),
      address: ChildAddressDto.fromJson(
        Map<String, dynamic>.from(json['address'] as Map? ?? {}),
      ),
      photoUrl: _value(json, 'photo_url', 'photoUrl')?.toString(),
      isInDebt:
          _value(json, 'is_in_debt', 'isInDebt') == true ||
          _value(json, 'is_in_debt', 'isInDebt') == 1 ||
          _value(json, 'is_inadimplent', 'isInadimplent') == true ||
          _value(json, 'is_inadimplent', 'isInadimplent') == 1,
      createdAt: _value(json, 'created_at', 'createdAt') != null
          ? DateTime.tryParse(
              _value(json, 'created_at', 'createdAt').toString(),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cpf': cpf,
      if (birthDate != null) 'birth_date': birthDate!.toIso8601String(),
      'school_name': schoolName,
      'shift_id': shiftId,
      'shift_name': shiftName,
      'parent_id': parentId,
      'parent_name': parentName,
      'address': address.toJson(),
      if (photoUrl != null) 'photo_url': photoUrl,
      'is_in_debt': isInDebt,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Child toDomain() {
    return Child(
      id: id,
      name: name,
      cpf: cpf,
      birthDate: birthDate,
      schoolName: schoolName,
      shiftId: shiftId,
      shiftName: shiftName,
      parentId: parentId,
      parentName: parentName,
      address: address.toDomain(),
      photoUrl: photoUrl,
      isInDebt: isInDebt,
      createdAt: createdAt,
    );
  }

  factory ChildDto.fromDomain(Child child) {
    return ChildDto(
      id: child.id,
      name: child.name,
      cpf: child.cpf,
      birthDate: child.birthDate,
      schoolName: child.schoolName,
      shiftId: child.shiftId,
      shiftName: child.shiftName,
      parentId: child.parentId,
      parentName: child.parentName,
      address: ChildAddressDto.fromDomain(child.address),
      photoUrl: child.photoUrl,
      isInDebt: child.isInDebt,
      createdAt: child.createdAt,
    );
  }
}

class ChildAddressDto {
  const ChildAddressDto({
    required this.street,
    required this.number,
    this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.zipCode,
    this.latitude,
    this.longitude,
  });

  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String zipCode;
  final double? latitude;
  final double? longitude;

  factory ChildAddressDto.fromJson(Map<String, dynamic> json) {
    return ChildAddressDto(
      street: (json['street'] ?? '').toString(),
      number: (json['number'] ?? '').toString(),
      complement: json['complement']?.toString(),
      neighborhood: (json['neighborhood'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      zipCode: (_value(json, 'zip_code', 'zipCode') ?? '').toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'number': number,
      if (complement != null) 'complement': complement,
      'neighborhood': neighborhood,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  ChildAddress toDomain() {
    return ChildAddress(
      street: street,
      number: number,
      complement: complement,
      neighborhood: neighborhood,
      city: city,
      state: state,
      zipCode: zipCode,
      latitude: latitude,
      longitude: longitude,
    );
  }

  factory ChildAddressDto.fromDomain(ChildAddress address) {
    return ChildAddressDto(
      street: address.street,
      number: address.number,
      complement: address.complement,
      neighborhood: address.neighborhood,
      city: address.city,
      state: address.state,
      zipCode: address.zipCode,
      latitude: address.latitude,
      longitude: address.longitude,
    );
  }
}

Object? _value(Map<String, dynamic> json, String snakeCase, String camelCase) {
  if (json.containsKey(snakeCase)) return json[snakeCase];
  return json[camelCase];
}
