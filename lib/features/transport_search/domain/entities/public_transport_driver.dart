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
  });

  final int id;
  final String name;
  final String? cellPhone;
  final String? information;
  final String? avatarUrl;
  final String? vehicleImageUrl;
  final List<String> schools;
  final List<String> districts;
  final List<int> shiftIds;

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
    );
  }
}
