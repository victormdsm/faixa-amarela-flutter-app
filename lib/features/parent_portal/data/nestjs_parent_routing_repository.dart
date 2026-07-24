import 'package:dio/dio.dart';

import '../../../core/models/paginated_result.dart';
import '../../../core/network/api_exception.dart';

class NestjsParentRoutingRepository {
  NestjsParentRoutingRepository(this._dio);

  final Dio _dio;

  Future<PaginatedResult<Map<String, dynamic>>> getRoutes() async {
    try {
      final response = await _dio.get<List<dynamic>>('/parent/routes');
      final items = (response.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
      return PaginatedResult<Map<String, dynamic>>(
        items: items,
        currentPage: 1,
        lastPage: 1,
        total: items.length,
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<PaginatedResult<Map<String, dynamic>>> getBoardings() async {
    try {
      final response = await _dio.get<List<dynamic>>('/parent/boardings');
      final items = (response.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
      return PaginatedResult<Map<String, dynamic>>(
        items: items,
        currentPage: 1,
        lastPage: 1,
        total: items.length,
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
