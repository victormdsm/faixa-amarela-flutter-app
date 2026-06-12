import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/models/paginated_result.dart';
import 'app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  Future<PaginatedResult<AppNotification>> notifications(
    String authHeader, {
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: {'page': page, 'limit': perPage},
        options: Options(headers: {'Authorization': authHeader}),
      );

      final json = response.data ?? const <String, dynamic>{};

      // NestJS returns: { data: [...], meta: { total, page, limit, totalPages } }
      // Laravel returns: { data: [...], current_page, last_page, total }
      final rawList = (json['data'] as List?) ?? const [];
      final meta = json['meta'] as Map<String, dynamic>?;
      final currentPage =
          (meta?['page'] as num?)?.toInt() ??
          (json['current_page'] as num?)?.toInt() ??
          1;
      final lastPage =
          (meta?['totalPages'] as num?)?.toInt() ??
          (json['last_page'] as num?)?.toInt() ??
          1;
      final total =
          (meta?['total'] as num?)?.toInt() ??
          (json['total'] as num?)?.toInt() ??
          rawList.length;

      return PaginatedResult<AppNotification>(
        items: rawList
            .whereType<Map>()
            .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false),
        currentPage: currentPage,
        lastPage: lastPage,
        total: total,
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<int> unreadCount(String authHeader) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/notifications/unread-count',
        options: Options(headers: {'Authorization': authHeader}),
      );
      final data = response.data;
      if (data == null) return 0;
      return (data['count'] as num?)?.toInt() ??
          (data['unread_count'] as num?)?.toInt() ??
          0;
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> markAsRead(String authHeader, String id) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        '/notifications/$id/read',
        options: Options(headers: {'Authorization': authHeader}),
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> markAllAsRead(String authHeader) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        '/notifications/read-all',
        options: Options(headers: {'Authorization': authHeader}),
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> saveDeviceToken(String authHeader, String? token) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        '/users/me/device-token',
        data: {'deviceToken': token},
        options: Options(headers: {'Authorization': authHeader}),
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
