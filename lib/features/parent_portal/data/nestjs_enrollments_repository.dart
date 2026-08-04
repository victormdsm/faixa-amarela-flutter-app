import 'package:dio/dio.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/dto/enrollment_dto.dart';
import '../../../domain/models/enrollment.dart';
import '../../../domain/repositories/enrollments_repository.dart';

class NestjsEnrollmentsRepository implements EnrollmentsRepository {
  NestjsEnrollmentsRepository(this._dio);

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
  Future<List<Enrollment>> getPendingEnrollments() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/parent/enrollments/pending',
      );
      final raw = response.data ?? const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map((e) => EnrollmentDto.fromJson(e).toDomain())
          .toList(growable: false);
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<List<Enrollment>> getActiveEnrollments() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/parent/enrollments/active',
      );
      final raw = response.data ?? const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map((e) => EnrollmentDto.fromJson(e).toDomain())
          .toList(growable: false);
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> acceptEnrollment(int id) async {
    try {
      await _dio.put(
        '/parent/enrollments/$id/accept',
        data: const <String, dynamic>{},
      );
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> rejectEnrollment(int id) async {
    try {
      await _dio.put(
        '/parent/enrollments/$id/reject',
        data: const <String, dynamic>{},
      );
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> cancelEnrollment(int id) async {
    try {
      await _dio.put(
        '/parent/enrollments/$id/cancel',
        data: const <String, dynamic>{},
      );
    } catch (e) {
      throw _mapException(e);
    }
  }

  // ── Driver-only operations (not supported on parent-side repository) ──

  @override
  Future<ChildLookupResult> lookupChildByCode(String code) async {
    throw UnsupportedError('lookupChildByCode is a driver-only operation.');
  }

  @override
  Future<void> requestEnrollment(int childId) async {
    throw UnsupportedError('requestEnrollment is a driver-only operation.');
  }

  @override
  Future<List<Enrollment>> getMyEnrollments() async {
    throw UnsupportedError('getMyEnrollments is a driver-only operation.');
  }
}
