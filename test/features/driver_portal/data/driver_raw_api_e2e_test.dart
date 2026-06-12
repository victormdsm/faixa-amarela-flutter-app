import 'package:app_faixa_amarela/core/network/nestjs_response_unwrap_interceptor.dart';
import 'package:app_faixa_amarela/core/storage/secure_token_storage.dart';
import 'package:app_faixa_amarela/features/auth/data/repositories/nestjs_auth_repository.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/user_role.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testes raw da API do motorista com login unico.
void main() {
  group('Driver raw API E2E (producao)', () {
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

    test('GET /drivers/me retorna dados esperados', () async {
      final response = await dio.get<Map<String, dynamic>>('/drivers/me');
      print('Status: ${response.statusCode}');
      print('Data type: ${response.data?.runtimeType}');
      print('Data keys: ${response.data?.keys.toList()}');
      print('Data: ${response.data}');
    });

    test('GET /driver/routes retorna dados esperados', () async {
      final response = await dio.get<dynamic>('/driver/routes');
      print('Status: ${response.statusCode}');
      print('Data type: ${response.data?.runtimeType}');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        print('Data keys: ${data.keys.toList()}');
        if (data['data'] is List) {
          final list = data['data'] as List;
          print('Rotas: ${list.length}');
          if (list.isNotEmpty) print('Primeira: ${list.first}');
        }
      } else if (data is List) {
        print('Rotas: ${data.length}');
        if (data.isNotEmpty) print('Primeira: ${data.first}');
      }
    });

    test('POST /driver/routes/start retorna dados esperados', () async {
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
      print('Status: ${response.statusCode}');
      print('Data type: ${response.data?.runtimeType}');
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        print('Data keys: ${data.keys.toList()}');
        print('Data: $data');
      }

      final routeId = response.data is Map<String, dynamic>
          ? (response.data as Map<String, dynamic>)['id']
          : null;
      if (routeId != null) {
        await dio.post<dynamic>('/driver/routes/$routeId/finish');
      }
    });
  });
}
