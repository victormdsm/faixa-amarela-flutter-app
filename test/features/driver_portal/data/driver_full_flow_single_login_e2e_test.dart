@Tags(['prod'])
library;

// ignore_for_file: avoid_print

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

/// Valida TODAS as rotas do motorista em um unico fluxo com login unico.
/// Isso evita multiplos logins e e mais estavel contra rate-limits da API.
void main() {
  group('Driver full flow E2E (producao) - login unico', () {
    late Dio dio;
    late SecureTokenStorage storage;
    late NestjsAuthRepository authRepo;
    late NestjsDriverRepository driverRepo;
    late NestjsRoutesRepository routesRepo;
    late NestjsDriverEnrollmentsRepository enrollmentsRepo;
    late CatalogRepository catalogRepo;
    late NotificationRepository notificationsRepo;

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
      driverRepo = NestjsDriverRepository(dio);
      routesRepo = NestjsRoutesRepository(dio);
      enrollmentsRepo = NestjsDriverEnrollmentsRepository(dio);
      catalogRepo = CatalogRepository(dio);
      notificationsRepo = NotificationRepository(dio);

      final session = await authRepo.signIn(
        email: 'aoextremogames@gmail.com',
        password: 'Escolabetta1234',
        role: UserRole.driver,
      );
      expect(session.accessToken, isNotEmpty);
      expect(session.user.isDriver, isTrue);
      dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    });

    tearDownAll(() async {
      // Garante que nao fica rota ativa pendente.
      try {
        final active = await routesRepo.getActiveRoute();
        if (active != null) {
          await routesRepo.finishRoute(active.id);
        }
      } catch (_) {
        // ignora
      }
    });

    test('fluxo completo de motorista', timeout: const Timeout(Duration(seconds: 120)), () async {
      // 1. Catalogos publicos
      final schools = await catalogRepo.listSchools();
      final districts = await catalogRepo.listDistricts();
      final shifts = await catalogRepo.listShifts();
      expect(schools, isNotEmpty);
      expect(districts, isNotEmpty);
      expect(shifts, isNotEmpty);
      print('Catalogos OK - escolas:${schools.length} bairros:${districts.length} turnos:${shifts.length}');

      // 2. Perfil
      final profile = await driverRepo.getDriverProfile();
      expect(profile, isNotNull);
      expect(profile!.id, greaterThan(0));
      expect(profile.name, isNotEmpty);
      expect(profile.vanId, greaterThan(0));
      expect(profile.vanPlate, isNotEmpty);
      expect(profile.schools, isNotEmpty);
      expect(profile.districts, isNotEmpty);
      print('Perfil OK: ${profile.name} | ${profile.vanPlate}');

      // 3. Atualiza perfil (CNH/informacoes)
      final updated = await driverRepo.updateBasicProfile(
        name: 'Victor - teste',
        cellPhone: '45984169058',
        information: 'Atualizado via E2E',
        cnh: '03412482578',
      );
      expect(updated.licenseNumber, '03412482578');
      print('Update perfil OK: cnh=${updated.licenseNumber} info=${updated.information}');

      // 4. Lista rotas historicas
      final routes = await routesRepo.listDriverRoutes();
      expect(routes, isNotEmpty);
      print('Listagem rotas OK: ${routes.length} rotas');

      // 5. Garante nenhuma rota ativa
      final activeBefore = await routesRepo.getActiveRoute();
      if (activeBefore != null) {
        await routesRepo.finishRoute(activeBefore.id);
      }
      final after = await routesRepo.getActiveRoute();
      expect(after, isNull);
      print('Nenhuma rota ativa OK');

      // 6. Start / Active / Finish
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

      // 7. Matriculas
      final enrollments = await enrollmentsRepo.getMyEnrollments();
      expect(enrollments, isA<List>());
      print('Enrollments OK: ${enrollments.length} matriculas');

      // 8. Notificacoes
      final authHeader = dio.options.headers['Authorization']!.toString();
      final notifications = await notificationsRepo.notifications(authHeader);
      expect(notifications.items, isA<List>());
      print('Notifications OK: ${notifications.items.length} notificacoes');

      final count = await notificationsRepo.unreadCount(authHeader);
      expect(count, greaterThanOrEqualTo(0));
      print('Unread count OK: $count');
    });
  });
}
