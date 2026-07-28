class Child {
  const Child({
    required this.id,
    required this.name,
    required this.cpf,
    required this.schoolId,
    required this.shiftId,
    this.uuid,
    this.isInDebt = false,
    this.createdAt,
    this.photoUrl,
  });

  final int id;
  final String name;
  final String cpf;

  /// Identificador público estável (LGPD): o responsável compartilha este
  /// código com o motorista em vez do CPF da criança.
  final String? uuid;
  final int? schoolId;
  final int? shiftId;
  final bool isInDebt;
  final DateTime? createdAt;
  final String? photoUrl;

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      cpf: (json['cpf'] ?? '').toString(),
      uuid: json['uuid']?.toString(),
      schoolId: (json['schoolId'] as num?)?.toInt(),
      shiftId: (json['shiftId'] as num?)?.toInt(),
      isInDebt: json['isInDebt'] == true || json['isInDebt'] == 1,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      photoUrl: json['photoUrl']?.toString(),
    );
  }
}

class ChildAddress {
  const ChildAddress({
    required this.street,
    required this.number,
    this.complement,
    this.zipCode,
    this.district,
    this.city,
    this.state,
    this.latitude,
    this.longitude,
  });

  final String street;
  final String number;
  final String? complement;
  final String? zipCode;

  /// Bairro (opcional — preenchido pelo reverse geocoding quando disponível).
  final String? district;

  /// Cidade/UF selecionadas no formulário (obrigatórias na UI) ou resolvidas
  /// pelo geocoding. Enviadas ao backend quando presentes.
  final String? city;
  final String? state;

  /// Coordenadas confirmadas no mapa (geocode + ajuste manual do marcador).
  /// Quando presentes, o backend as grava direto, sem chamar o geocoder.
  final double? latitude;
  final double? longitude;

  factory ChildAddress.fromJson(Map<String, dynamic> json) {
    return ChildAddress(
      street: (json['street'] ?? '').toString(),
      number: (json['number'] ?? '').toString(),
      complement: json['complement']?.toString(),
      zipCode: (json['zipCode'] ?? '').toString(),
      district: json['district']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'number': number,
      if (complement != null && complement!.trim().isNotEmpty)
        'complement': complement,
      if (zipCode != null && zipCode!.trim().isNotEmpty) 'zipCode': zipCode,
      if (district != null && district!.trim().isNotEmpty) 'district': district,
      if (city != null && city!.trim().isNotEmpty) 'city': city,
      if (state != null && state!.trim().isNotEmpty) 'state': state,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
