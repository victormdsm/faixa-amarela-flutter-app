import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/public_transport_driver.dart';

class PublicTransportSearchRepository {
  PublicTransportSearchRepository(this._dio);

  final Dio _dio;

  Future<List<PublicTransportDriver>> search({
    int? schoolId,
    int? districtId,
    int? shiftId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/public-transport/search',
        queryParameters: {
          ...?_entry('schoolId', schoolId),
          ...?_entry('districtId', districtId),
          ...?_entry('shiftId', shiftId),
          'perPage': 100,
        },
      );

      final root = response.data ?? const <String, dynamic>{};
      final raw = (root['data'] as List?) ?? const [];
      return raw
          .whereType<Map>()
          .map(
            (e) => PublicTransportDriver.fromJson(Map<String, dynamic>.from(e)),
          )
          .where((e) => e.id > 0)
          .toList(growable: false);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Map<String, dynamic>? _entry(String key, int? value) {
    if (value == null) return null;
    return {key: value};
  }
}
