class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) decoder,
  ) {
    final rawList = (json['data'] as List?) ?? const [];
    return PaginatedResult<T>(
      items: rawList
          .whereType<Map>()
          .map((e) => decoder(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toInt() ?? rawList.length,
    );
  }
}
