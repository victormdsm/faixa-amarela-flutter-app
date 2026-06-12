import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';

class NestjsDriverProfileChangeRequestRepository {
  NestjsDriverProfileChangeRequestRepository(this._dio);
  final Dio _dio;

  Future<String> uploadImage(String filePath) async {
    try {
      final form = FormData.fromMap({});
      form.files.add(MapEntry('image', await MultipartFile.fromFile(filePath)));
      final response = await _dio.post<Map<String, dynamic>>(
        '/driver/profile-change-requests/upload-image',
        data: form,
      );
      final data = response.data;
      if (data == null) {
        throw ApiException(message: 'Resposta vazia do servidor.');
      }
      final url = data['imageUrl'] ?? data['image_url'];
      if (url == null) {
        throw ApiException(message: 'URL da imagem nao retornada.');
      }
      return url.toString();
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> submitRequest({
    required List<int> schoolIds,
    required Map<int, List<int>> districtShiftMap,
    String? avatarImagePath,
    String? vehicleImagePath,
    int? vehicleId,
    String? requestNote,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/driver/profile-change-requests',
        data: {
          'requestedSchoolIds': jsonEncode(schoolIds),
          'requestedDistrictShiftMap': jsonEncode(
            districtShiftMap.entries
                .map((e) => {'district_id': e.key, 'shift_ids': e.value})
                .toList(growable: false),
          ),
          'requestedAvatarPath': avatarImagePath,
          'requestedVehicleImagePath': vehicleImagePath,
          'vehicleId': vehicleId,
          'requestNote': requestNote,
        },
      );
      return response.data ?? const <String, dynamic>{};
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
