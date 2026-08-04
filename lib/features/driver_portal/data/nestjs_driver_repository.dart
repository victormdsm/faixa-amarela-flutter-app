import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/dto/driver_profile_dto.dart';
import '../../../domain/models/driver_profile.dart';
import '../../../domain/repositories/driver_repository.dart';

class NestjsDriverRepository implements DriverRepository {
  NestjsDriverRepository(this._dio);

  final Dio _dio;

  @override
  Future<DriverProfile?> getDriverProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/drivers/me');
      final data = response.data;
      if (data == null) return null;

      if (data['id'] == null && data['userId'] == null) {
        return null;
      }

      return DriverProfileDto.fromJson(data).toDomain();
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<DriverProfile> updateBasicProfile({
    required String name,
    String? cellPhone,
    String? information,
    String? cnh,
  }) async {
    try {
      // 1. Atualiza dados do motorista (CNH e informacoes).
      // APP-11: quando o parametro vem nao-nulo, o motorista editou o campo —
      // envia o valor mesmo vazio (''), pois o backend aceita '' como limpeza.
      final driverPayload = <String, dynamic>{};
      if (cnh != null) {
        driverPayload['cnh'] = cnh.trim();
      }
      if (information != null) {
        driverPayload['information'] = information.trim();
      }

      late final Map<String, dynamic> driverProfileData;
      if (driverPayload.isNotEmpty) {
        final driverResponse = await _dio.put<Map<String, dynamic>>(
          '/drivers/me',
          data: driverPayload,
        );
        driverProfileData = driverResponse.data ?? const <String, dynamic>{};
      } else {
        final driverResponse = await _dio.get<Map<String, dynamic>>(
          '/drivers/me',
        );
        driverProfileData = driverResponse.data ?? const <String, dynamic>{};
      }

      // 2. Atualiza dados do usuario (nome e telefone). Telefone editado para
      // vazio vai como '' para limpar o dado no servidor (APP-11).
      final userPayload = <String, dynamic>{};
      if (name.trim().isNotEmpty) userPayload['name'] = name.trim();
      if (cellPhone != null) {
        userPayload['cellPhone'] = cellPhone.trim();
      }

      Map<String, dynamic>? userData;
      if (userPayload.isNotEmpty) {
        final userResponse = await _dio.put<Map<String, dynamic>>(
          '/users/me',
          data: userPayload,
        );
        userData = userResponse.data;
      }

      // 3. Mescla os dados para retornar um DriverProfile atualizado.
      final merged = Map<String, dynamic>.from(driverProfileData);
      if (userData != null) {
        if (userData['name'] != null) merged['name'] = userData['name'];
        if (userData['cellPhone'] != null) {
          merged['cellPhone'] = userData['cellPhone'];
        }
        if (userData['avatarUrl'] != null) {
          merged['avatarUrl'] = userData['avatarUrl'];
        }
      }

      return DriverProfileDto.fromJson(merged).toDomain();
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> updateVehiclePublicContact({
    String? publicContactName,
    String? publicContactPhone,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (publicContactName != null) {
        payload['publicContactName'] = publicContactName.trim();
      }
      if (publicContactPhone != null) {
        payload['publicContactPhone'] = publicContactPhone.trim();
      }
      if (payload.isEmpty) return;

      await _dio.put<Map<String, dynamic>>(
        '/drivers/me/vehicle',
        data: payload,
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
