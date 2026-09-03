class PublicTransportDriver {
  const PublicTransportDriver({
    required this.id,
    required this.name,
    required this.cellPhone,
    required this.information,
    required this.avatarUrl,
    required this.vehicleImageUrl,
    required this.districts,
    this.publicContactName,
    this.publicContactPhone,
    this.vehicleDescription,
    this.vehiclePlate,
  });

  final int id;
  final String name;

  /// Contato retornado pela busca pública. O backend já envia aqui o
  /// telefone PÚBLICO cadastrado na van (nunca o celular pessoal — LGPD).
  final String? cellPhone;
  final String? information;
  final String? avatarUrl;
  final String? vehicleImageUrl;
  final List<String> districts;

  /// Nome/telefone de contato público da van (exibidos no detalhe).
  final String? publicContactName;
  final String? publicContactPhone;

  /// Descrição da van montada pelo backend ("marca • cor • ano").
  final String? vehicleDescription;

  /// Placa da van — opcional no contrato público; oculta quando ausente.
  final String? vehiclePlate;

  /// Telefone público preferencial para contato (WhatsApp/ligação).
  String? get contactPhone {
    final public = (publicContactPhone ?? '').trim();
    if (public.isNotEmpty) return publicContactPhone;
    return cellPhone;
  }

  /// Descrição pública do motorista (sobre) — campo `information`.
  String? get about {
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
      districts: names(json['districts']),
      publicContactName: json['publicContactName']?.toString(),
      publicContactPhone: json['publicContactPhone']?.toString(),
      vehicleDescription: json['vehicleDescription']?.toString(),
      vehiclePlate: json['vehiclePlate']?.toString(),
    );
  }
}
