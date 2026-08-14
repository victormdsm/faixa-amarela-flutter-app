import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/dto/enrollment_dto.dart';
import '../../../domain/models/enrollment.dart';
import '../../../domain/repositories/enrollments_repository.dart';

class NestjsDriverEnrollmentsRepository implements DriverEnrollmentsRepository {
  NestjsDriverEnrollmentsRepository(this._dio);

  final Dio _dio;

  @override
  Future<ChildLookupResult> lookupChildByCode(String code) async {
    try {
      // Contrato novo: o endpoint aceita APENAS o código UUID v4 da criança
      // (CPF/RG retornam 400). O nome do parâmetro na wire foi mantido.
      final response = await _dio.get<Map<String, dynamic>>(
        '/driver/children/lookup-by-cpf',
        queryParameters: {'cpf': code},
      );
      final data = response.data ?? const <String, dynamic>{};
      return ChildLookupResult.fromJson(data);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> requestEnrollment(String childUuid) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/driver/enrollments',
        data: {'child_uuid': childUuid},
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<List<Enrollment>> getMyEnrollments() async {
    try {
      final response = await _dio.get<List<dynamic>>('/driver/enrollments');
      final raw = response.data ?? const [];

      return raw
          .whereType<Map<String, dynamic>>()
          .map((e) => EnrollmentDto.fromJson(e).toDomain())
          .toList(growable: false);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// Desvincula uma matrícula da carteira do motorista (ativa ou pendente).
  @override
  Future<void> cancelEnrollment(int id) async {
    try {
      await _dio.put(
        '/driver/enrollments/$id/cancel',
        data: const <String, dynamic>{},
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  // ---------------------------------------------------------------------------
  // Parent-side actions — not used by driver portal
  // ---------------------------------------------------------------------------

  @override
  Future<List<Enrollment>> getPendingEnrollments() {
    throw UnsupportedError('getPendingEnrollments is a parent-side action.');
  }

  @override
  Future<List<Enrollment>> getActiveEnrollments() {
    throw UnsupportedError('getActiveEnrollments is a parent-side action.');
  }

  @override
  Future<void> acceptEnrollment(int id) {
    throw UnsupportedError('acceptEnrollment is a parent-side action.');
  }

  @override
  Future<void> rejectEnrollment(int id) {
    throw UnsupportedError('rejectEnrollment is a parent-side action.');
  }
}
