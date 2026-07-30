import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../domain/models/driver_profile_change_request.dart';

class NestjsDriverProfileChangeRequestRepository {
  NestjsDriverProfileChangeRequestRepository(this._dio);
  final Dio _dio;

  Future<String> uploadImage(String filePath, {required String type}) async {
    try {
      final form = FormData.fromMap({});
      form.files.add(MapEntry('image', await MultipartFile.fromFile(filePath)));
      final response = await _dio.post<Map<String, dynamic>>(
        '/driver/profile-change-requests/upload-image',
        queryParameters: {'type': type},
        data: form,
      );
      final data = response.data;
      if (data == null) {
        throw ApiException(message: 'Resposta vazia do servidor.');
      }
      final url = data['imageUrl'];
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
    /// Mapa bairro→turnos desejado. Null = motorista não editou bairros/
    /// turnos — a chave `requestedDistrictShiftMap` é omitida e o backend
    /// não toca na cobertura atual (APP-02).
    required Map<int, List<int>>? districtShiftMap,
    String? avatarImagePath,
    String? vehicleImagePath,
    int? vehicleId,
    String? requestNote,
    String? requestedVehiclePlaca,
    String? requestedVehicleMarca,
    String? requestedVehicleCor,
    String? requestedVehicleAno,
  }) async {
    try {
      final districtShiftMapJson = districtShiftMap == null
          ? null
          : jsonEncode(
              districtShiftMap.entries
                  .map((e) => {'districtId': e.key, 'shiftIds': e.value})
                  .toList(growable: false),
            );
      final response = await _dio.post<Map<String, dynamic>>(
        '/driver/profile-change-requests',
        data: {
          'requestedSchoolIds': jsonEncode(schoolIds),
          'requestedDistrictShiftMap': ?districtShiftMapJson,
          'requestedAvatarPath': avatarImagePath,
          'requestedVehicleImagePath': vehicleImagePath,
          'vehicleId': vehicleId,
          'requestNote': requestNote,
          // Dados da van trafegam apenas quando editados: a aplicação deles
          // passa a depender da aprovação do admin (não são persistidos
          // direto no perfil). Ausentes = sem alteração de veículo.
          'requestedVehiclePlaca': ?requestedVehiclePlaca,
          'requestedVehicleMarca': ?requestedVehicleMarca,
          'requestedVehicleCor': ?requestedVehicleCor,
          'requestedVehicleAno': ?requestedVehicleAno,
        },
      );
      return response.data ?? const <String, dynamic>{};
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<DriverProfileChangeRequest>> listMyRequests() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/driver/profile-change-requests',
      );
      final data = response.data;
      if (data == null) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(DriverProfileChangeRequest.fromJson)
          .toList(growable: false);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
