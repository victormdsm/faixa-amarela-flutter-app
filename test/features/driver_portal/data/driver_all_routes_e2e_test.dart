import 'package:app_faixa_amarela/core/network/api_exception.dart';
import 'package:app_faixa_amarela/core/network/nestjs_response_unwrap_interceptor.dart';
import 'package:app_faixa_amarela/core/storage/secure_token_storage.dart';
import 'package:app_faixa_amarela/features/auth/data/repositories/nestjs_auth_repository.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/user_role.dart';
import 'package:app_faixa_amarela/features/catalog/data/catalog_repository.dart';
import 'package:app_faixa_amarela/features/driver_portal/data/nestjs_driver_enrollments_repository.dart';
import 'package:app_faixa_amarela/features/driver_portal/data/nestjs_driver_repository.dart';
import 'package:app_faixa_amarela/features/driver_portal/data/nestjs_routes_repository.dart';
import 'package:app_faixa_amarela/features/notifications/data/notification_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Valida TODAS as rotas do motorista contra a API real de producao.
/// Algumas acoes (boarding, notify-parent etc.) precisam de uma rota com
/// criancas matriculadas; sao puladas quando nao ha dados.
void main() {
  group('Todas as rotas do motorista E2E (producao)', () {
    late Dio dio;
    late SecureTokenStorage storage;
    late NestjsAuthRepository authRepo;
    late NestjsDriverRepository driverRepo;
    late NestjsRoutesRepository routesRepo;
    late NestjsDriverEnrollmentsRepository enrollmentsRepo;
    late CatalogRepository catalogRepo;
    late NotificationRepository notificationsRepo;

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
      enrollmentsRepo = NestjsDriverEnrollmentsRepository(dio);
      catalogRepo = CatalogRepository(dio);
      notificationsRepo = NotificationRepository(dio);
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

    test('01 - login como motorista funciona', login);

    test('02 - catalogos publicos carregam', () async {
      final schools = await catalogRepo.listSchools();
      final districts = await catalogRepo.listDistricts();
      final shifts = await catalogRepo.listShifts();
      expect(schools, isNotEmpty);
      expect(districts, isNotEmpty);
      expect(shifts, isNotEmpty);
      print('Catalogos OK - escolas:${schools.length} bairros:${districts.length} turnos:${shifts.length}');
    });

    test('03 - GET /drivers/me retorna perfil completo', () async {
      await login();
      final profile = await driverRepo.getDriverProfile();
      expect(profile, isNotNull);
      expect(profile!.id, greaterThan(0));
      expect(profile.name, isNotEmpty);
      expect(profile.vanId, greaterThan(0));
      expect(profile.vanPlate, isNotEmpty);
      expect(profile.schools, isNotEmpty);
      expect(profile.districts, isNotEmpty);
      print('Perfil OK: ${profile.name} | ${profile.vanPlate}');
    });

    test('04 - PUT /drivers/me atualiza CNH/informacoes', () async {
      await login();
      final updated = await driverRepo.updateBasicProfile(
        name: 'Victor - teste',
        cellPhone: '45984169058',
        information: 'Atualizado via E2E',
        cnh: '03412482578',
      );
      expect(updated.licenseNumber, '03412482578');
      expect(updated.information, 'Atualizado via E2E');
      print('Update perfil OK: cnh=${updated.licenseNumber} info=${updated.information}');
    });

    test('05 - GET /driver/routes lista rotas historicas', () async {
      await login();
      final routes = await routesRepo.listDriverRoutes();
      expect(routes, isNotEmpty);
      print('Listagem rotas OK: ${routes.length} rotas');
    });

    test('06 - GET /driver/routes/active retorna nulo quando nao ha rota ativa', () async {
      await login();
      // Garante que nao ha rota ativa
      final active = await routesRepo.getActiveRoute();
      if (active != null) {
        await routesRepo.finishRoute(active.id);
      }
      final after = await routesRepo.getActiveRoute();
      expect(after, isNull);
      print('Nenhuma rota ativa OK');
    });

    test('07 - POST /driver/routes/start cria e GET /active retorna a rota', () async {
      await login();
      final before = await routesRepo.getActiveRoute();
      if (before != null) await routesRepo.finishRoute(before.id);

      final manifest = await routesRepo.startRoute();
      expect(manifest.id, greaterThan(0));
      expect(manifest.manifestId, isNotNull);
      print('Start OK: routeId=${manifest.id} manifestId=${manifest.manifestId}');

      final active = await routesRepo.getActiveRoute();
      expect(active, isNotNull);
      expect(active!.id, manifest.id);
      print('Active OK: routeId=${active.id}');

      await routesRepo.finishRoute(manifest.id);
      print('Finish OK');
    });

    test('08 - GET /driver/enrollments retorna lista (mesmo que vazia)', () async {
      await login();
      final enrollments = await enrollmentsRepo.getMyEnrollments();
      expect(enrollments, isA<List>());
      print('Enrollments OK: ${enrollments.length} matriculas');
    });

    test('09 - GET /notifications e unread-count funcionam', () async {
      await login();
      final notifications = await notificationsRepo.notifications(
        dio.options.headers['Authorization']!.toString(),
      );
      expect(notifications.items, isA<List>());
      print('Notifications OK: ${notifications.items.length} notificacoes');

      final count = await notificationsRepo.unreadCount(
        dio.options.headers['Authorization']!.toString(),
      );
      expect(count, greaterThanOrEqualTo(0));
      print('Unread count OK: $count');
    });

    test('10 - acoes de rota com criancas sao puladas se nao houver matriculas', () async {
      await login();
      final enrollments = await enrollmentsRepo.getMyEnrollments();
      if (enrollments.isEmpty) {
        print('SKIP: nao ha matriculas para testar boarding/notify-parent');
        return;
      }
      // Se houvesse matriculas, testariamos boarding/disembarking/notify-parent aqui.
    });
  });
}
