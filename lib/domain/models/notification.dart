class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.read = false,
    this.createdAt,
    this.metadata,
  });

  final int id;
  final int userId;
  final String title;
  final String body;
  final String type;
  final bool read;
  final DateTime? createdAt;
  final Map<String, dynamic>? metadata;
}
