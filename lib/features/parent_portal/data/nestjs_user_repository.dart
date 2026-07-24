import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/repositories/user_repository.dart';

class NestjsUserRepository implements UserRepository {
  NestjsUserRepository(this._dio);

  final Dio _dio;

  Map<String, dynamic> _unwrapData(Map<String, dynamic>? data) {
    // O interceptor NestjsResponseUnwrapInterceptor já remove o envelope
    // { data: ..., meta?: ... }; aqui garantimos apenas o tipo correto.
    if (data == null) return const <String, dynamic>{};
    return data;
  }

  @override
  Future<UserProfile> getMe() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/me');
      return UserProfile.fromJson(_unwrapData(response.data));
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<UserProfile> updateMe({String? name, String? cellPhone}) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) payload['name'] = name.trim();
      if (cellPhone != null) payload['cellPhone'] = cellPhone.trim();
      // Avatar deve ser enviado apenas via [uploadAvatar]; o DTO de update
      // do backend nao aceita esse campo.

      final response = await _dio.put<Map<String, dynamic>>(
        '/users/me',
        data: payload,
      );
      return UserProfile.fromJson(_unwrapData(response.data));
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<UserProfile> uploadAvatar(String filePath) async {
    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/users/me/avatar',
        data: form,
      );
      return UserProfile.fromJson(_unwrapData(response.data));
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        '/users/me/password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
