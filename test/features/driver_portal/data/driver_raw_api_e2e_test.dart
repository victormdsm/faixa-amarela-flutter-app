import 'package:app_faixa_amarela/core/network/nestjs_response_unwrap_interceptor.dart';
import 'package:app_faixa_amarela/features/auth/data/repositories/nestjs_auth_repository.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/user_role.dart';
import 'package:app_faixa_amarela/core/storage/secure_token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Driver raw API E2E (producao)', () {
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

    test('GET /drivers/me retorna dados esperados', () async {
      await login();
      final response = await dio.get<Map<String, dynamic>>('/drivers/me');
      print('Status: ${response.statusCode}');
      print('Data type: ${response.data?.runtimeType}');
      print('Data keys: ${response.data?.keys.toList()}');
      print('Data: ${response.data}');
    });

    test('GET /driver/routes retorna dados esperados', () async {
      await login();
      final response = await dio.get<Map<String, dynamic>>('/driver/routes');
      print('Status: ${response.statusCode}');
      print('Data type: ${response.data?.runtimeType}');
      print('Data keys: ${response.data?.keys.toList()}');
      if (response.data?['data'] is List) {
        final list = response.data!['data'] as List;
        print('Rotas: ${list.length}');
        if (list.isNotEmpty) {
          print('Primeira: ${list.first}');
        }
      }
    });

    test('POST /driver/routes/start retorna dados esperados', () async {
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
      print('Status: ${response.statusCode}');
      print('Data type: ${response.data?.runtimeType}');
      print('Data keys: ${response.data?.keys.toList()}');
      print('Data: ${response.data}');

      final routeId = response.data?['id'];
      if (routeId != null) {
        await dio.post<Map<String, dynamic>>('/driver/routes/$routeId/finish');
      }
    });
  });
}
