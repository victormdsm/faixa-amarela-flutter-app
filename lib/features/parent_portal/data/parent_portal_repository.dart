import 'package:dio/dio.dart';

import '../../../core/models/paginated_result.dart';
import '../../../core/network/api_exception.dart';

class ParentPortalRepository {
  ParentPortalRepository(this._dio);

  final Dio _dio;

  Future<PaginatedResult<Map<String, dynamic>>> children(String authHeader) {
    return _getPaginated('/parents/children', authHeader);
  }

  Future<PaginatedResult<Map<String, dynamic>>> routes(String authHeader) {
    return _getPaginated('/parents/routes', authHeader);
  }

  Future<PaginatedResult<Map<String, dynamic>>> boardings(String authHeader) {
    return _getPaginated('/parents/boardings', authHeader);
  }

  Future<Map<String, dynamic>> createDependent(
    String authHeader, {
    required String name,
    required int relativeId,
    required int schoolId,
    required int shiftId,
    String? sex,
    int? age,
    String? avatarImagePath,
  }) async {
    try {
      final hasAvatar =
          avatarImagePath != null && avatarImagePath.trim().isNotEmpty;
      final payload = <String, dynamic>{
        'name': name,
        'relative_id': relativeId,
        'school_id': schoolId,
        'shift_id': shiftId,
        ...?_stringEntry('sex', sex),
        ...?_numEntry('age', age),
      };

      final response = hasAvatar
          ? await _dio.post<Map<String, dynamic>>(
              '/parents/dependents',
              options: Options(headers: {'Authorization': authHeader}),
              data: FormData.fromMap({
                ...payload,
                'avatar_image':
                    await MultipartFile.fromFile(avatarImagePath.trim()),
              }),
            )
          : await _dio.post<Map<String, dynamic>>(
              '/parents/dependents',
              options: Options(headers: {'Authorization': authHeader}),
              data: payload,
            );
      return response.data ?? const <String, dynamic>{};
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> updateDependent(
    String authHeader,
    int dependentId, {
    required String name,
    required int relativeId,
    required int schoolId,
    required int shiftId,
    String? sex,
    int? age,
    String? avatarImagePath,
  }) async {
    try {
      final hasAvatar =
          avatarImagePath != null && avatarImagePath.trim().isNotEmpty;
      final payload = <String, dynamic>{
        'name': name,
        'relative_id': relativeId,
        'school_id': schoolId,
        'shift_id': shiftId,
        ...?_stringEntry('sex', sex),
        ...?_numEntry('age', age),
      };

      if (!hasAvatar) {
        final response = await _dio.put<Map<String, dynamic>>(
          '/parents/dependents/$dependentId',
          options: Options(headers: {'Authorization': authHeader}),
          data: payload,
        );
        return response.data ?? const <String, dynamic>{};
      }

      // Laravel cannot parse multipart on PUT; use POST + method override.
      final response = await _dio.post<Map<String, dynamic>>(
        '/parents/dependents/$dependentId',
        options: Options(headers: {'Authorization': authHeader}),
        data: FormData.fromMap({
          ...payload,
          '_method': 'PUT',
          'avatar_image': await MultipartFile.fromFile(avatarImagePath.trim()),
        }),
      );
      return response.data ?? const <String, dynamic>{};
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> deleteDependent(String authHeader, int dependentId) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        '/parents/dependents/$dependentId',
        options: Options(headers: {'Authorization': authHeader}),
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<PaginatedResult<Map<String, dynamic>>> _getPaginated(
    String path,
    String authHeader,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        options: Options(headers: {'Authorization': authHeader}),
      );
      return PaginatedResult<Map<String, dynamic>>.fromJson(
        response.data ?? const <String, dynamic>{},
        (json) => json,
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Map<String, dynamic>? _stringEntry(String key, String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return {key: trimmed};
  }

  Map<String, dynamic>? _numEntry(String key, num? value) {
    if (value == null) return null;
    return {key: value};
  }
}
