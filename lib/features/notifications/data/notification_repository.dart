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

      final json = response.data;

      // O interceptor preserva o envelope { data: [...], meta: {...} } para
      // endpoints paginados. Portanto lemos a lista em data['data'] e os
      // metadados em data['meta'].
      final envelope = json is Map<String, dynamic> ? json : null;
      final rawList = envelope?['data'] as List<dynamic>? ?? <dynamic>[];
      final meta = envelope?['meta'] as Map<String, dynamic>?;
      final currentPage = (meta?['page'] as num?)?.toInt() ?? 1;
      final lastPage = (meta?['totalPages'] as num?)?.toInt() ?? 1;
      final total = (meta?['total'] as num?)?.toInt() ?? rawList.length;

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
      return (data['count'] as num?)?.toInt() ?? 0;
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
