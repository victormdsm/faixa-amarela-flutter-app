import 'package:app_faixa_amarela/core/network/api_exception.dart';
import 'package:app_faixa_amarela/core/network/nestjs_response_unwrap_interceptor.dart';
import 'package:app_faixa_amarela/core/storage/secure_token_storage.dart';
import 'package:app_faixa_amarela/features/auth/data/repositories/nestjs_auth_repository.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/user_role.dart';
import 'package:app_faixa_amarela/features/driver_portal/data/nestjs_driver_repository.dart';
import 'package:app_faixa_amarela/features/driver_portal/data/nestjs_routes_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Driver flow E2E (producao)', () {
    late Dio dio;
    late SecureTokenStorage storage;
    late NestjsAuthRepository authRepo;
    late NestjsDriverRepository driverRepo;
    late NestjsRoutesRepository routesRepo;

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
      driverRepo = NestjsDriverRepository(dio);
      routesRepo = NestjsRoutesRepository(dio);
    });

    Future<void> login() async {
      final session = await authRepo.signIn(
        email: 'aoextremogames@gmail.com',
        password: 'Escolabetta1234',
        role: UserRole.driver,
      );
      expect(session.accessToken, isNotEmpty);
      expect(session.user.isDriver, isTrue);
      dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }

    test('login real funciona', login);

    test('getDriverProfile retorna perfil com van e coverage', () async {
      await login();
      try {
        final profile = await driverRepo.getDriverProfile();
        expect(profile, isNotNull);
        expect(profile!.id, greaterThan(0));
        expect(profile.name, isNotEmpty);
        expect(profile.vanId, greaterThan(0));
        expect(profile.vanPlate, isNotEmpty);
        expect(profile.schools, isNotEmpty);
        expect(profile.districts, isNotEmpty);
        print('Perfil: ${profile.name} | Van: ${profile.vanPlate}');
        print('Escolas: ${profile.schools.length}');
        print('Bairros: ${profile.districts.length}');
      } on ApiException catch (e) {
        print('ApiException: ${e.message} | status: ${e.statusCode}');
        print('DioError type: ${e.toString()}');
        rethrow;
      } catch (e, st) {
        print('Erro inesperado: $e');
        print(st);
        rethrow;
      }
    });

    test('listDriverRoutes retorna rotas historicas', () async {
      await login();
      try {
        final routes = await routesRepo.listDriverRoutes();
        expect(routes, isNotEmpty);
        print('Rotas historicas: ${routes.length}');
        print('Primeira rota id: ${routes.first['id']}');
      } on ApiException catch (e) {
        print('ApiException: ${e.message} | status: ${e.statusCode}');
        rethrow;
      } catch (e, st) {
        print('Erro inesperado: $e');
        print(st);
        rethrow;
      }
    });

    test('startRoute cria rota ativa e retorna manifesto valido', () async {
      await login();

      try {
        // Finaliza rota ativa se existir
        final activeBefore = await routesRepo.getActiveRoute();
        if (activeBefore != null) {
          await routesRepo.finishRoute(activeBefore.id);
        }

        final manifest = await routesRepo.startRoute();
        expect(manifest.id, greaterThan(0));
        expect(manifest.manifestId, isNotNull);
        expect(manifest.manifestId, isNotEmpty);
        expect(manifest.vanId, greaterThan(0));
        print('Rota criada: ${manifest.id} | Manifest: ${manifest.manifestId}');

        final activeAfter = await routesRepo.getActiveRoute();
        expect(activeAfter, isNotNull);
        expect(activeAfter!.id, manifest.id);

        await routesRepo.finishRoute(manifest.id);
      } on ApiException catch (e) {
        print('ApiException: ${e.message} | status: ${e.statusCode}');
        rethrow;
      } catch (e, st) {
        print('Erro inesperado: $e');
        print(st);
        rethrow;
      }
    });
  });
}
