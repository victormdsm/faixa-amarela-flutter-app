import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/dto/driver_profile_dto.dart';
import '../../../../domain/models/driver_profile.dart';
import '../../../../domain/repositories/driver_repository.dart';

class NestjsDriverRepository implements DriverRepository {
  NestjsDriverRepository(this._dio);

  final Dio _dio;

  @override
  Future<DriverProfile?> getDriverProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/drivers/me');
      final data = response.data;
      if (data == null) return null;

      final profileData = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;

      if (profileData['id'] == null && profileData['user_id'] == null) {
        return null;
      }

      return DriverProfileDto.fromJson(profileData).toDomain();
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<DriverProfile> updateBasicProfile({
    required String name,
    String? email,
    String? cellPhone,
    String? information,
    String? cnh,
  }) async {
    try {
      // 1. Atualiza dados do motorista (CNH e informacoes).
      final driverPayload = <String, dynamic>{};
      if (cnh != null && cnh.trim().isNotEmpty) {
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
        driverProfileData = driverResponse.data?['data'] is Map<String, dynamic>
            ? driverResponse.data!['data'] as Map<String, dynamic>
            : driverResponse.data ?? const <String, dynamic>{};
      } else {
        final driverResponse = await _dio.get<Map<String, dynamic>>('/drivers/me');
        driverProfileData = driverResponse.data?['data'] is Map<String, dynamic>
            ? driverResponse.data!['data'] as Map<String, dynamic>
            : driverResponse.data ?? const <String, dynamic>{};
      }

      // 2. Atualiza dados do usuario (nome e telefone).
      final userPayload = <String, dynamic>{};
      if (name.trim().isNotEmpty) userPayload['name'] = name.trim();
      if (cellPhone != null && cellPhone.trim().isNotEmpty) {
        userPayload['cellPhone'] = cellPhone.trim();
      }

      Map<String, dynamic>? userData;
      if (userPayload.isNotEmpty) {
        final userResponse = await _dio.put<Map<String, dynamic>>(
          '/users/me',
          data: userPayload,
        );
        userData = userResponse.data?['data'] is Map<String, dynamic>
            ? userResponse.data!['data'] as Map<String, dynamic>
            : userResponse.data;
      }

      // 3. Mescla os dados para retornar um DriverProfile atualizado.
      final merged = Map<String, dynamic>.from(driverProfileData);
      if (userData != null) {
        if (userData['name'] != null) merged['name'] = userData['name'];
        if (userData['cellPhone'] != null) {
          merged['cellPhone'] = userData['cellPhone'];
        }
        if (userData['avatarUrl'] != null) {
          merged['avatar_url'] = userData['avatarUrl'];
        }
      }

      return DriverProfileDto.fromJson(merged).toDomain();
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
