class PublicTransportDriver {
  const PublicTransportDriver({
    required this.id,
    required this.name,
    required this.cellPhone,
    required this.information,
    required this.avatarUrl,
    required this.vehicleImageUrl,
    required this.schools,
    required this.districts,
    required this.shiftIds,
    this.cnh,
    this.description,
    this.publicContactName,
    this.publicContactPhone,
    this.vehicleDescription,
    this.vehiclePlate,
    this.shifts = const [],
  });

  final int id;
  final String name;

  /// Contato retornado pela busca pública. O backend já envia aqui o
  /// telefone PÚBLICO cadastrado na van (nunca o celular pessoal — LGPD).
  final String? cellPhone;
  final String? information;
  final String? avatarUrl;
  final String? vehicleImageUrl;
  final List<String> schools;
  final List<String> districts;
  final List<int> shiftIds;

  /// CNH do motorista (contrato novo da busca pública).
  final String? cnh;

  /// Descrição pública do motorista (campo novo do driver). Quando ausente,
  /// a UI cai no campo legado [information].
  final String? description;

  /// Nome/telefone de contato público da van (exibidos no detalhe).
  final String? publicContactName;
  final String? publicContactPhone;

  /// Descrição da van montada pelo backend ("marca • cor • ano").
  final String? vehicleDescription;

  /// Placa da van — opcional no contrato público; oculta quando ausente.
  final String? vehiclePlate;

  /// Nomes dos turnos atendidos (para os chips do detalhe).
  final List<String> shifts;

  /// Telefone público preferencial para contato (WhatsApp/ligação).
  String? get contactPhone {
    final public = (publicContactPhone ?? '').trim();
    if (public.isNotEmpty) return publicContactPhone;
    return cellPhone;
  }

  /// Descrição pública preferencial: campo novo `description`, caindo no
  /// legado `information` quando o backend ainda não o envia.
  String? get about {
    final desc = (description ?? '').trim();
    if (desc.isNotEmpty) return description;
    final info = (information ?? '').trim();
    if (info.isNotEmpty) return information;
    return null;
  }

  factory PublicTransportDriver.fromJson(Map<String, dynamic> json) {
    List<String> names(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(growable: false);
    }

    List<int> ids(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<num>()
          .map((e) => e.toInt())
          .toSet()
          .toList(growable: false);
    }

    int parseId(dynamic raw) {
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw) ?? 0;
      return 0;
    }

    return PublicTransportDriver(
      id: parseId(json['id']),
      name: (json['name'] ?? '').toString(),
      cellPhone: json['phone']?.toString(),
      information: json['information']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      vehicleImageUrl: json['vehicleImageUrl']?.toString(),
      schools: names(json['schools']),
      districts: names(json['districts']),
      shiftIds: ids(json['shiftIds']),
      cnh: json['cnh']?.toString(),
      description: json['description']?.toString(),
      publicContactName: json['publicContactName']?.toString(),
      publicContactPhone: json['publicContactPhone']?.toString(),
      vehicleDescription: json['vehicleDescription']?.toString(),
      vehiclePlate: json['vehiclePlate']?.toString(),
      shifts: names(json['shifts']),
    );
  }
}
