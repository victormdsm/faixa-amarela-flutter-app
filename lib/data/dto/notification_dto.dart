import '../../domain/models/notification.dart';

class NotificationDto {
  const NotificationDto({
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

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      read: json['read'] == true || json['read'] == 1,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'read': read,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  AppNotification toDomain() {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      read: read,
      createdAt: createdAt,
      metadata: metadata,
    );
  }

  factory NotificationDto.fromDomain(AppNotification notification) {
    return NotificationDto(
      id: notification.id,
      userId: notification.userId,
      title: notification.title,
      body: notification.body,
      type: notification.type,
      read: notification.read,
      createdAt: notification.createdAt,
      metadata: notification.metadata,
    );
  }
}
