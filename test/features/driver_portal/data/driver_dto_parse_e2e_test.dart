import 'package:app_faixa_amarela/core/network/nestjs_response_unwrap_interceptor.dart';
import 'package:app_faixa_amarela/core/storage/secure_token_storage.dart';
import 'package:app_faixa_amarela/data/dto/driver_profile_dto.dart';
import 'package:app_faixa_amarela/data/dto/route_manifest_dto.dart';
import 'package:app_faixa_amarela/features/auth/data/repositories/nestjs_auth_repository.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/user_role.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Driver DTO parse E2E (producao)', () {
    late Dio dio;
    late SecureTokenStorage storage;
    late NestjsAuthRepository authRepo;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.faixaamarela.com.br/api/v1',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      dio.interceptors.add(NestjsResponseUnwrapInterceptor());
      storage = SecureTokenStorage();
      authRepo = NestjsAuthRepository(dio, storage);
    });

    Future<void> login() async {
      final session = await authRepo.signIn(
        email: 'aoextremogames@gmail.com',
        password: 'Escolabetta1234',
        role: UserRole.driver,
      );
      dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }

    test('DriverProfileDto parseia /drivers/me', () async {
      await login();
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
      await login();
      final response = await dio.get<Map<String, dynamic>>('/driver/routes/active');
      final data = response.data;
      if (data == null || data.isEmpty) {
        print('Sem rota ativa');
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
      await login();

      // Finaliza rota ativa se existir
      final active = await dio.get<Map<String, dynamic>>('/driver/routes/active');
      if (active.data != null && active.data!.isNotEmpty) {
        final routeId = active.data!['id'];
        if (routeId != null) {
          await dio.post<Map<String, dynamic>>('/driver/routes/$routeId/finish');
        }
      }

      final response = await dio.post<Map<String, dynamic>>(
        '/driver/routes/start',
        data: const <String, dynamic>{},
      );
      final data = response.data!;
      print('Raw route: $data');
      final manifestData = data['manifest'] as Map<String, dynamic>;
      final manifest = RouteManifestDto.fromJson(manifestData).toDomain();
      expect(manifest.id, greaterThan(0));
      expect(manifest.manifestId, isNotNull);
      print('Parse OK: routeId=${manifest.id} manifestId=${manifest.manifestId}');

      await dio.post<Map<String, dynamic>>('/driver/routes/${manifest.id}/finish');
    });
  });
}
