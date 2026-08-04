class CatalogOption {
  const CatalogOption({required this.id, required this.name, this.shifts = const []});

  final int id;
  final String name;
  /// Turnos da escola (preenchido apenas para o tipo "schools" pelo backend).
  final List<CatalogOption> shifts;

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

    return CatalogOption(
      id: id,
      name: (json['name'] ?? json['shiftName'] ?? '').toString(),
      shifts: shifts,
    );
  }
}
