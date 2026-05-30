class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime? createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? 'Notificacao').toString(),
      body: (json['body'] ?? '').toString(),
      data: Map<String, dynamic>.from((json['data'] as Map?) ?? const {}),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      readAt: DateTime.tryParse((json['read_at'] ?? '').toString()),
    );
  }
}
