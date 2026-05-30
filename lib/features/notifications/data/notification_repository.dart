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
        queryParameters: {'page': page, 'per_page': perPage},
        options: Options(headers: {'Authorization': authHeader}),
      );

      return PaginatedResult<AppNotification>.fromJson(
        response.data ?? const <String, dynamic>{},
        AppNotification.fromJson,
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
      return (response.data?['unread_count'] as num?)?.toInt() ?? 0;
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
        '/auth/device-token',
        data: {'device_token': token},
        options: Options(headers: {'Authorization': authHeader}),
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
