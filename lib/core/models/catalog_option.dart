class CatalogOption {
  const CatalogOption({
    required this.id,
    required this.name,
    this.shifts = const [],
    this.cityId,
  });

  final int id;
  final String name;
  /// Turnos da escola (preenchido apenas para o tipo "schools" pelo backend).
  final List<CatalogOption> shifts;

  /// Cidade do item (escolas e bairros expõem `cityId`; demais catálogos não).
  final int? cityId;

  factory CatalogOption.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    int id;
    if (rawId is num) {
      id = rawId.toInt();
    } else if (rawId is String) {
      id = int.tryParse(rawId) ?? 0;
    } else {
      id = 0;
    }

    final rawShifts = json['shifts'];
    final shifts = rawShifts is List
        ? rawShifts
            .whereType<Map>()
            .map((e) => CatalogOption.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.id > 0 && e.name.trim().isNotEmpty)
            .toList(growable: false)
        : const <CatalogOption>[];

    final rawCityId = json['cityId'] ?? json['city_id'];
    final int? cityId = switch (rawCityId) {
      final num n => n.toInt(),
      final String s => int.tryParse(s),
      _ => null,
    };

    return CatalogOption(
      id: id,
      name: (json['name'] ?? '').toString(),
      shifts: shifts,
      cityId: cityId != null && cityId > 0 ? cityId : null,
    );
  }
}
