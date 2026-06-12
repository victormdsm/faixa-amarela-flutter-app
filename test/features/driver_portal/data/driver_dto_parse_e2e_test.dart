import 'package:app_faixa_amarela/core/network/nestjs_response_unwrap_interceptor.dart';
import 'package:app_faixa_amarela/core/storage/secure_token_storage.dart';
import 'package:app_faixa_amarela/data/dto/driver_profile_dto.dart';
import 'package:app_faixa_amarela/data/dto/route_manifest_dto.dart';
import 'package:app_faixa_amarela/features/auth/data/repositories/nestjs_auth_repository.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/user_role.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testes de parse de DTOs do motorista com login unico.
void main() {
  group('Driver DTO parse E2E (producao)', () {
    late Dio dio;
    late SecureTokenStorage storage;
    late NestjsAuthRepository authRepo;

    setUpAll(() async {
      FlutterSecureStorage.setMockInitialValues({});
      dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.faixaamarela.com.br/api/v1',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      dio.interceptors.add(NestjsResponseUnwrapInterceptor());
      storage = SecureTokenStorage();
      authRepo = NestjsAuthRepository(dio, storage);

      final session = await authRepo.signIn(
        email: 'aoextremogames@gmail.com',
        password: 'Escolabetta1234',
        role: UserRole.driver,
      );
      expect(session.accessToken, isNotEmpty);
      dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    });

    tearDownAll(() async {
      try {
        final active = await dio.get<dynamic>('/driver/routes/active');
        final activeData = active.data;
        if (activeData is Map<String, dynamic> && activeData.isNotEmpty) {
          final routeId = activeData['id'];
          if (routeId != null) {
            await dio.post<dynamic>('/driver/routes/$routeId/finish');
          }
        }
      } catch (_) {
        // ignora
      }
    });

    test('DriverProfileDto parseia /drivers/me', () async {
      final response = await dio.get<Map<String, dynamic>>('/drivers/me');
      final data = response.data!;
      print('Raw: $data');
      final profile = DriverProfileDto.fromJson(data).toDomain();
      expect(profile.id, greaterThan(0));
      expect(profile.name, isNotEmpty);
      expect(profile.vanId, greaterThan(0));
      expect(profile.vanPlate, isNotEmpty);
      print('Parse OK: ${profile.name} | ${profile.vanPlate}');
    });

    test('RouteManifestDto parseia rota ativa', () async {
      final response = await dio.get<dynamic>('/driver/routes/active');
      final data = response.data;
      if (data == null || (data is Map && data.isEmpty)) {
        print('Sem rota ativa');
        return;
      }
      if (data is! Map<String, dynamic>) {
        print('Tipo inesperado para rota ativa: ${data.runtimeType}');
        return;
      }
      print('Raw route: $data');
      final manifestData = data['manifest'] as Map<String, dynamic>;
      final manifest = RouteManifestDto.fromJson(manifestData).toDomain();
      expect(manifest.id, greaterThan(0));
      expect(manifest.manifestId, isNotNull);
      print('Parse OK: routeId=${manifest.id} manifestId=${manifest.manifestId}');
    });

    test('RouteManifestDto parseia POST /driver/routes/start', () async {
      // Finaliza rota ativa se existir
      final active = await dio.get<dynamic>('/driver/routes/active');
      final activeData = active.data;
      if (activeData is Map<String, dynamic> && activeData.isNotEmpty) {
        final routeId = activeData['id'];
        if (routeId != null) {
          await dio.post<dynamic>('/driver/routes/$routeId/finish');
        }
      }

      final response = await dio.post<dynamic>(
        '/driver/routes/start',
        data: const <String, dynamic>{},
      );
      final data = response.data! as Map<String, dynamic>;
      print('Raw route: $data');
      final manifestData = data['manifest'] as Map<String, dynamic>;
      final manifest = RouteManifestDto.fromJson(manifestData).toDomain();
      expect(manifest.id, greaterThan(0));
      expect(manifest.manifestId, isNotNull);
      print('Parse OK: routeId=${manifest.id} manifestId=${manifest.manifestId}');

      await dio.post<dynamic>('/driver/routes/${manifest.id}/finish');
    });
  });
}
