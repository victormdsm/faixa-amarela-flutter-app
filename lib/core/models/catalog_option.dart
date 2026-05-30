class CatalogOption {
  const CatalogOption({required this.id, required this.name});

  final int id;
  final String name;

  factory CatalogOption.fromJson(Map<String, dynamic> json) {
    return CatalogOption(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? json['shift_name'] ?? '').toString(),
    );
  }
}
