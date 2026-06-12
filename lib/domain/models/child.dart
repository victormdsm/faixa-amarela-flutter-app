class Child {
  const Child({
    required this.id,
    required this.name,
    required this.cpf,
    required this.birthDate,
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
  final ChildAddress address;
  final String? photoUrl;
  final bool isInDebt;
  final DateTime? createdAt;

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      cpf: (json['cpf'] ?? '').toString(),
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date'].toString())
          : null,
      schoolName: (json['school_name'] ?? '').toString(),
      shiftId: (json['shift_id'] as num?)?.toInt() ?? 0,
      shiftName: (json['shift_name'] ?? '').toString(),
      parentId: (json['parent_id'] as num?)?.toInt() ?? 0,
      parentName: (json['parent_name'] ?? '').toString(),
      address: ChildAddress.fromJson(
        Map<String, dynamic>.from(json['address'] as Map? ?? {}),
      ),
      photoUrl: json['photo_url']?.toString(),
      isInDebt: json['is_in_debt'] == true || json['is_in_debt'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class ChildAddress {
  const ChildAddress({
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

  factory ChildAddress.fromJson(Map<String, dynamic> json) {
    return ChildAddress(
      street: (json['street'] ?? '').toString(),
      number: (json['number'] ?? '').toString(),
      complement: json['complement']?.toString(),
      neighborhood: (json['neighborhood'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      zipCode: (json['zip_code'] ?? '').toString(),
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
}
