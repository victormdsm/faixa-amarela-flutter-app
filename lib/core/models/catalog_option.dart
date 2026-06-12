class CatalogOption {
  const CatalogOption({required this.id, required this.name});

  final int id;
  final String name;

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

    return CatalogOption(
      id: id,
      name: (json['name'] ?? json['shift_name'] ?? json['shiftName'] ?? '')
          .toString(),
    );
  }
}
