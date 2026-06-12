import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/dto/child_dto.dart';
import '../../../../data/dto/enrollment_dto.dart';
import '../../../../domain/models/enrollment.dart';
import '../../../../domain/repositories/enrollments_repository.dart';

class NestjsDriverEnrollmentsRepository implements EnrollmentsRepository {
  NestjsDriverEnrollmentsRepository(this._dio);

  final Dio _dio;

  @override
  Future<ChildLookupResult> lookupChildByCpf(String cpf) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/driver/children/lookup-by-cpf',
        queryParameters: {'cpf': cpf},
      );
      final data = response.data ?? const <String, dynamic>{};

      // Prefer nested child DTO when available
      if (data['child'] is Map<String, dynamic>) {
        final childDto = ChildDto.fromJson(
          data['child'] as Map<String, dynamic>,
        );
        return ChildLookupResult(
          found: true,
          childId: childDto.id,
          childName: childDto.name,
          schoolName: childDto.schoolName,
          shiftName: childDto.shiftName,
          parentName: childDto.parentName,
          address: _formatAddress(childDto.address),
          isInDebt: childDto.isInDebt,
          hasPendingEnrollment:
              data['has_pending_enrollment'] == true ||
              data['has_pending_enrollment'] == 1,
        );
      }

      return ChildLookupResult.fromJson(data);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  String? _formatAddress(ChildAddressDto address) {
    final parts = <String>[
      address.street,
      address.number,
      address.neighborhood,
      address.city,
    ].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  @override
  Future<void> requestEnrollment(int childId) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/driver/enrollments',
        data: {'childId': childId},
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

  // ---------------------------------------------------------------------------
  // Parent-side actions — not used by driver portal
  // ---------------------------------------------------------------------------

  @override
  Future<List<Enrollment>> getPendingEnrollments() async {
    throw UnsupportedError('getPendingEnrollments is a parent-side action.');
  }

  @override
  Future<void> acceptEnrollment(int id) async {
    throw UnsupportedError('acceptEnrollment is a parent-side action.');
  }

  @override
  Future<void> rejectEnrollment(int id) async {
    throw UnsupportedError('rejectEnrollment is a parent-side action.');
  }
}
