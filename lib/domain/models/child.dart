/// Tipos de documento aceitos no cadastro da criança (contrato do backend).
abstract final class ChildDocumentType {
  static const cpf = 'cpf';
  static const rg = 'rg';

  /// Normaliza valores vindos da API: ausente/desconhecido vira CPF
  /// (compat com respostas antigas, que não traziam `documentType`).
  static String parse(dynamic raw) {
    final value = (raw ?? '').toString().trim().toLowerCase();
    return value == rg ? rg : cpf;
  }
}

class Child {
  const Child({
    required this.id,
    required this.name,
    required this.cpf,
    required this.schoolId,
    required this.shiftId,
    this.documentType = ChildDocumentType.cpf,
    this.documentState,
    this.uuid,
    this.isInDebt = false,
    this.createdAt,
    this.photoUrl,
  });

  final int id;
  final String name;

  /// Número do documento da criança (CPF ou RG, conforme [documentType]).
  /// Mantido com o nome histórico `cpf` para minimizar o impacto da
  /// mudança de contrato (`cpf` → `document` no backend).
  final String cpf;

  /// Tipo do documento: [ChildDocumentType.cpf] (default) ou
  /// [ChildDocumentType.rg].
  final String documentType;

  /// UF emissora do RG (2 letras). Obrigatória quando [documentType] é RG;
  /// sempre null para CPF (o backend rejeita `documentState` com CPF).
  final String? documentState;

  /// Identificador público estável (LGPD): o responsável compartilha este
  /// código com o motorista em vez do CPF da criança.
  final String? uuid;
  final int? schoolId;
  final int? shiftId;
  final bool isInDebt;
  final DateTime? createdAt;
  final String? photoUrl;
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
