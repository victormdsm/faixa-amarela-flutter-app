import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/dto/child_dto.dart';
import '../../../domain/models/child.dart';
import '../../../domain/repositories/children_repository.dart';

class NestjsChildrenRepository implements ChildrenRepository {
  NestjsChildrenRepository(this._dio);

  final Dio _dio;

  String _cleanCpf(String cpf) => cpf.replaceAll(RegExp(r'[^0-9]'), '');

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
      // The NestJS response unwrap interceptor replaces the body with the
      // `data` payload, so the response is a List<dynamic> directly.
      final response = await _dio.get<List<dynamic>>('/parent/children');
      final raw = response.data ?? const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map((e) => ChildDto.fromJson(e).toDomain())
          .toList(growable: false);
    } catch (e) {
      debugPrint('[NestjsChildrenRepository.getChildren] ERRO: $e');
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
    required int? schoolId,
    required int? shiftId,
    required ChildAddress address,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/parent/children',
        data: <String, dynamic>{
          'name': name.trim(),
          'cpf': _cleanCpf(cpf),
          if (schoolId != null && schoolId > 0) 'schoolId': schoolId,
          if (shiftId != null && shiftId > 0) 'shiftId': shiftId,
        },
      );
      final body = response.data;
      if (body == null) {
        throw const ServerFailure(message: 'Resposta vazia do servidor.');
      }
      final child = ChildDto.fromJson(body).toDomain();

      await _createAddress(child.id, address);

      return child;
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<Child> updateChild({
    required int id,
    String? name,
    String? cpf,
    int? schoolId,
    int? shiftId,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null) payload['name'] = name.trim();
      if (cpf != null) payload['cpf'] = _cleanCpf(cpf);
      if (schoolId != null) {
        payload['schoolId'] = schoolId > 0 ? schoolId : null;
      }
      if (shiftId != null) payload['shiftId'] = shiftId > 0 ? shiftId : null;

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
      await _dio.delete(
        '/parent/children/$id',
        options: Options(contentType: null),
      );
    } catch (e) {
      throw _mapException(e);
    }
  }

  Future<void> _createAddress(
    int childId,
    ChildAddress address, {
    bool isDefault = true,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/parent/children/$childId/addresses',
      data: <String, dynamic>{
        'zipcode': (address.zipCode ?? '').trim(),
        'street': address.street.trim(),
        'number': address.number.trim(),
        'reference': address.complement?.trim(),
        'type': 'home',
        'isDefault': isDefault,
        if (address.latitude != null && address.longitude != null) ...{
          'latitude': address.latitude,
          'longitude': address.longitude,
        },
      },
    );
  }

  @override
  Future<({double latitude, double longitude, String? label})?>
  geocodeAddress(String text) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/parent/addresses/geocode',
        queryParameters: {'text': text},
      );
      final data = response.data;
      if (data == null) return null;
      final latitude = (data['latitude'] as num?)?.toDouble();
      final longitude = (data['longitude'] as num?)?.toDouble();
      if (latitude == null || longitude == null) return null;
      return (
        latitude: latitude,
        longitude: longitude,
        label: data['label']?.toString(),
      );
    } catch (_) {
      // Best-effort: 404 (não localizado) ou ORS fora simplesmente escondem
      // o mapa; o cadastro segue sem coordenadas, como antes.
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getChildAddresses(int childId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/parent/children/$childId/addresses',
      );
      return (response.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> updateChildAddress({
    required int childId,
    required int addressId,
    required ChildAddress address,
  }) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        '/parent/children/$childId/addresses/$addressId',
        data: <String, dynamic>{
          'zipcode': (address.zipCode ?? '').trim(),
          'street': address.street.trim(),
          'number': address.number.trim(),
          'reference': address.complement?.trim(),
          'type': 'home',
          'isDefault': true,
          if (address.latitude != null && address.longitude != null) ...{
            'latitude': address.latitude,
            'longitude': address.longitude,
          },
        },
      );
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> createChildAddress({
    required int childId,
    required ChildAddress address,
    bool isDefault = false,
  }) async {
    try {
      await _createAddress(childId, address, isDefault: isDefault);
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> deleteChildAddress({
    required int childId,
    required int addressId,
  }) async {
    try {
      await _dio.delete(
        '/parent/children/$childId/addresses/$addressId',
        options: Options(contentType: null),
      );
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> setChildAddressDefault({
    required int childId,
    required int addressId,
  }) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        '/parent/children/$childId/addresses/$addressId',
        data: const <String, dynamic>{'isDefault': true},
      );
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<Child> uploadChildPhoto({
    required int childId,
    required String filePath,
  }) async {
    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/parent/children/$childId/photo',
        data: form,
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
}
