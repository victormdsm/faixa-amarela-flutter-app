import 'package:dio/dio.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/dto/child_dto.dart';
import '../../../../domain/models/child.dart';
import '../../../../domain/repositories/children_repository.dart';

class NestjsChildrenRepository implements ChildrenRepository {
  NestjsChildrenRepository(this._dio);

  final Dio _dio;

  AppFailure _mapException(Object error) {
    final apiException = error is ApiException
        ? error
        : ApiException.fromDio(error);

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return TimeoutFailure(message: apiException.message);
        case DioExceptionType.connectionError:
          return NetworkFailure(message: apiException.message);
        default:
          break;
      }
    }

    return switch (apiException.statusCode) {
      401 => AuthFailure(message: apiException.message),
      403 => ForbiddenFailure(message: apiException.message),
      404 => NotFoundFailure(message: apiException.message),
      422 => ValidationFailure(message: apiException.message),
      _
          when apiException.statusCode != null &&
              apiException.statusCode! >= 500 =>
        ServerFailure(message: apiException.message),
      _ => ServerFailure(message: apiException.message),
    };
  }

  @override
  Future<List<Child>> getChildren() async {
    try {
      final response = await _dio.get<List<dynamic>>('/parent/children');
      final raw = response.data ?? const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map((e) => ChildDto.fromJson(e).toDomain())
          .toList(growable: false);
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<Child?> getChildById(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/parent/children/$id',
      );
      final data = response.data;
      if (data == null) return null;
      return ChildDto.fromJson(data).toDomain();
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<Child> createChild({
    required String name,
    required String cpf,
    required DateTime birthDate,
    required String schoolName,
    required int shiftId,
    required String shiftName,
    required int parentId,
    required String parentName,
    required ChildAddress address,
    String? photoUrl,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/parent/children',
        data: <String, dynamic>{
          'name': name.trim(),
          'cpf': cpf.trim(),
          'birth_date': birthDate.toIso8601String(),
          'school_name': schoolName.trim(),
          'shift_id': shiftId,
          'address': address.toJson(),
          if (photoUrl != null && photoUrl.trim().isNotEmpty)
            'photo_url': photoUrl.trim(),
        },
      );
      final data = response.data;
      if (data == null) {
        throw const ServerFailure(message: 'Resposta vazia do servidor.');
      }
      return ChildDto.fromJson(data).toDomain();
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<Child> updateChild({
    required int id,
    String? name,
    String? cpf,
    DateTime? birthDate,
    String? schoolName,
    int? shiftId,
    String? shiftName,
    int? parentId,
    String? parentName,
    ChildAddress? address,
    String? photoUrl,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null) payload['name'] = name.trim();
      if (cpf != null) payload['cpf'] = cpf.trim();
      if (birthDate != null) {
        payload['birth_date'] = birthDate.toIso8601String();
      }
      if (schoolName != null) payload['school_name'] = schoolName.trim();
      if (shiftId != null) payload['shift_id'] = shiftId;
      if (address != null) payload['address'] = address.toJson();
      if (photoUrl != null && photoUrl.trim().isNotEmpty) {
        payload['photo_url'] = photoUrl.trim();
      }

      final response = await _dio.put<Map<String, dynamic>>(
        '/parent/children/$id',
        data: payload,
      );
      final data = response.data;
      if (data == null) {
        throw const ServerFailure(message: 'Resposta vazia do servidor.');
      }
      return ChildDto.fromJson(data).toDomain();
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> deleteChild(int id) async {
    try {
      await _dio.delete('/parent/children/$id');
    } catch (e) {
      throw _mapException(e);
    }
  }
}
