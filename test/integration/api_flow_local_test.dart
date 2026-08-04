import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_faixa_amarela/core/network/backend_config.dart';
import 'package:app_faixa_amarela/core/network/nestjs_response_unwrap_interceptor.dart';
import 'package:app_faixa_amarela/core/storage/secure_token_storage.dart';
import 'package:app_faixa_amarela/domain/models/child.dart';
import 'package:app_faixa_amarela/domain/models/driver_route_summary.dart';
import 'package:app_faixa_amarela/domain/models/enrollment.dart';
import 'package:app_faixa_amarela/domain/models/parent_boarding_record.dart';
import 'package:app_faixa_amarela/domain/models/parent_route_summary.dart';
import 'package:app_faixa_amarela/domain/models/route_manifest.dart';
import 'package:app_faixa_amarela/features/auth/data/repositories/nestjs_auth_repository.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_session.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/user_role.dart';
import 'package:app_faixa_amarela/features/catalog/data/catalog_repository.dart';
import 'package:app_faixa_amarela/features/driver_portal/data/nestjs_driver_enrollments_repository.dart';
import 'package:app_faixa_amarela/features/driver_portal/data/nestjs_driver_profile_change_request_repository.dart';
import 'package:app_faixa_amarela/features/driver_portal/data/nestjs_driver_repository.dart';
import 'package:app_faixa_amarela/features/driver_portal/data/nestjs_routes_repository.dart';
import 'package:app_faixa_amarela/features/notifications/data/notification_repository.dart';
import 'package:app_faixa_amarela/features/parent_portal/data/nestjs_children_repository.dart';
import 'package:app_faixa_amarela/features/parent_portal/data/nestjs_enrollments_repository.dart';
import 'package:app_faixa_amarela/features/parent_portal/data/nestjs_parent_routing_repository.dart';
import 'package:app_faixa_amarela/features/transport_search/data/repositories/public_transport_search_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Teste de integração host ↔ Backend NestJS local.
///
/// Roda com `flutter test`, sem precisar de emulador/dispositivo.
/// Pré-requisitos:
///   - Backend rodando em `http://localhost:3000`.
///   - Contas ativadas criadas por `cd nestjs && bash scripts/e2e-setup.sh`.
///   - Roles e driver/van corretos no banco (veja script de setup).
///
/// Exemplo:
/// ```bash
/// cd app_faixa_amarela
/// flutter test test/integration/api_flow_local_test.dart \
///   --dart-define=PARENT_EMAIL=... \
///   --dart-define=PARENT_PASSWORD=... \
///   --dart-define=DRIVER_EMAIL=... \
///   --dart-define=DRIVER_PASSWORD=...
/// ```
void main() {
  const parentEmail = String.fromEnvironment('PARENT_EMAIL', defaultValue: '');
  const parentPassword = String.fromEnvironment(
    'PARENT_PASSWORD',
    defaultValue: '',
  );
  const driverEmail = String.fromEnvironment('DRIVER_EMAIL', defaultValue: '');
  const driverPassword = String.fromEnvironment(
    'DRIVER_PASSWORD',
    defaultValue: '',
  );

  final credentialsMissing =
      parentEmail.isEmpty ||
      parentPassword.isEmpty ||
      driverEmail.isEmpty ||
      driverPassword.isEmpty;

  group(
    'Flutter host ↔ NestJS API integration',
    skip: credentialsMissing
        ? 'Credenciais de teste não definidas. '
              'Rode `cd nestjs && bash scripts/e2e-setup.sh` e passe as credenciais via --dart-define: '
              'PARENT_EMAIL, PARENT_PASSWORD, DRIVER_EMAIL, DRIVER_PASSWORD'
        : false,
    () {
      late Dio dio;
      late SecureTokenStorage storage;
      late NestjsAuthRepository authRepo;
      late CatalogRepository catalogRepo;
      late NestjsChildrenRepository childrenRepo;
      late NestjsDriverEnrollmentsRepository driverEnrollmentsRepo;
      late NestjsEnrollmentsRepository parentEnrollmentsRepo;
      late NestjsDriverRepository driverRepo;
      late NestjsRoutesRepository routesRepo;
      late NestjsParentRoutingRepository parentRoutingRepo;
      late NotificationRepository notificationRepo;
      late PublicTransportSearchRepository publicTransportRepo;
      late NestjsDriverProfileChangeRequestRepository profileChangeRepo;

      late AuthSession parentSession;
      late AuthSession driverSession;

      setUpAll(() async {
        FlutterSecureStorage.setMockInitialValues({});

        dio = Dio(
          BaseOptions(
            baseUrl: BackendConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );
        dio.interceptors.add(NestjsResponseUnwrapInterceptor());
        storage = SecureTokenStorage();

        authRepo = NestjsAuthRepository(dio, storage);
        catalogRepo = CatalogRepository(dio);
        childrenRepo = NestjsChildrenRepository(dio);
        driverEnrollmentsRepo = NestjsDriverEnrollmentsRepository(dio);
        parentEnrollmentsRepo = NestjsEnrollmentsRepository(dio);
        driverRepo = NestjsDriverRepository(dio);
        routesRepo = NestjsRoutesRepository(dio);
        parentRoutingRepo = NestjsParentRoutingRepository(dio);
        notificationRepo = NotificationRepository(dio);
        publicTransportRepo = PublicTransportSearchRepository(dio);
        profileChangeRepo = NestjsDriverProfileChangeRequestRepository(dio);

        // Realiza logins uma única vez para evitar throttling.
        parentSession = await authRepo.signIn(
          email: parentEmail,
          password: parentPassword,
          role: UserRole.parent,
        );
        driverSession = await authRepo.signIn(
          email: driverEmail,
          password: driverPassword,
          role: UserRole.driver,
        );

        // Limpa rotas ativas pendentes de execuções anteriores.
        dio.options.headers['Authorization'] =
            'Bearer ${driverSession.accessToken}';
        try {
          final active = await routesRepo.getActiveRoute();
          if (active != null) {
            await routesRepo.finishRoute(active.id);
          }
        } catch (_) {
          // Ignora falhas de limpeza.
        }
      });

      setUp(() async {
        // Reseta o header a cada teste; cada teste define conforme necessário.
        dio.options.headers.remove('Authorization');

        // Garante que nenhuma rota ativa de execuções anteriores persista.
        dio.options.headers['Authorization'] =
            'Bearer ${driverSession.accessToken}';
        try {
          final active = await routesRepo.getActiveRoute();
          if (active != null) {
            await routesRepo.finishRoute(active.id);
          }
        } catch (_) {
          // Ignora falhas de limpeza.
        }
      });

      test('parent login succeeds', () {
        expect(parentSession.accessToken, isNotEmpty);
        expect(parentSession.user.isParent, isTrue);
        expect(parentSession.user.isActivated, isTrue);
      });

      test('driver login succeeds', () {
        expect(driverSession.accessToken, isNotEmpty);
        expect(driverSession.user.isDriver, isTrue);
        expect(driverSession.user.isActivated, isTrue);
      });

      test(
        'full flow: parent creates child, driver enrolls, parent accepts',
        () async {
          dio.options.headers['Authorization'] =
              'Bearer ${parentSession.accessToken}';

          // 1. Busca um turno válido no catálogo
          final shifts = await catalogRepo.listShifts();
          expect(shifts, isNotEmpty, reason: 'Catálogo de turnos vazio');
          final shift = shifts.first;

          // 2. Cria criança
          final uniqueCpf = _generateCpf();
          final createdChild = await childrenRepo.createChild(
            name: 'Criança Integração',
            document: uniqueCpf,
            schoolId: null,
            shiftId: shift.id,
            address: const ChildAddress(
              street: 'Rua Integração',
              number: '42',
              complement: 'Apto 1',
              zipCode: '85851000',
            ),
          );

          expect(createdChild.id, greaterThan(0));
          expect(createdChild.name, 'Criança Integração');
          expect(createdChild.cpf, uniqueCpf);
          expect(createdChild.shiftId, shift.id);

          // 3. Lista filhos do pai
          final children = await childrenRepo.getChildren();
          expect(children.any((c) => c.id == createdChild.id), isTrue);

          // 4. Motorista busca criança pelo código (UUID) — CPF foi removido
          // do lookup (backend responde 400 para documentos).
          dio.options.headers['Authorization'] =
              'Bearer ${driverSession.accessToken}';
          final childCode = children
              .firstWhere((c) => c.id == createdChild.id)
              .uuid;
          expect(childCode, isNotNull, reason: 'Criança sem código (uuid)');
          final lookup = await driverEnrollmentsRepo.lookupChildByCode(
            childCode!,
          );
          expect(lookup.found, isTrue);
          expect(lookup.childId, createdChild.id);
          expect(lookup.childName, 'Criança Integração');

          // 5. Motorista solicita matrícula
          await driverEnrollmentsRepo.requestEnrollment(createdChild.id);

          // 6. Pai lista e aceita matrícula
          dio.options.headers['Authorization'] =
              'Bearer ${parentSession.accessToken}';
          final pending = await parentEnrollmentsRepo.getPendingEnrollments();
          expect(pending, isNotEmpty);
          final enrollment = pending.firstWhere(
            (e) => e.childId == createdChild.id,
            orElse: () => fail('Matrícula pendente não encontrada'),
          );

          await parentEnrollmentsRepo.acceptEnrollment(enrollment.id);

          // 7. Verifica que não há mais pendências para essa criança
          final pendingAfter = await parentEnrollmentsRepo
              .getPendingEnrollments();
          expect(
            pendingAfter.any((e) => e.childId == createdChild.id),
            isFalse,
          );

          // 8. Motorista confirma matrícula ativa
          dio.options.headers['Authorization'] =
              'Bearer ${driverSession.accessToken}';
          final driverEnrollments = await driverEnrollmentsRepo
              .getMyEnrollments();
          expect(
            driverEnrollments.any(
              (e) =>
                  e.childId == createdChild.id &&
                  e.status == EnrollmentStatus.active,
            ),
            isTrue,
          );
        },
        timeout: const Timeout(Duration(minutes: 2)),
      );

      test('driver profile and planning options are coherent', () async {
        dio.options.headers['Authorization'] =
            'Bearer ${driverSession.accessToken}';

        final profile = await driverRepo.getDriverProfile();
        expect(profile, isNotNull);
        expect(profile!.id, greaterThan(0), reason: 'driver profile id');
        expect(profile.userId, greaterThan(0), reason: 'driver profile userId');
        expect(profile.vanId, greaterThan(0), reason: 'driver profile vanId');
        expect(profile.vanPlate, isNotEmpty, reason: 'driver profile vanPlate');

        final planning = await routesRepo.getPlanningOptions();
        expect(planning.vans, isNotEmpty);
        expect(planning.vans.first.id, greaterThan(0));

        final routes = await routesRepo.listDriverRoutes();
        expect(routes, isA<List<DriverRouteSummary>>());
      });

      test('parent routes and boardings endpoints are reachable', () async {
        dio.options.headers['Authorization'] =
            'Bearer ${parentSession.accessToken}';

        final routes = await parentRoutingRepo.getRoutes();
        expect(routes.items, isA<List<ParentRouteSummary>>());

        final boardings = await parentRoutingRepo.getBoardings();
        expect(boardings.items, isA<List<ParentBoardingRecord>>());
      });

      test('notifications unread-count returns int', () async {
        final count = await notificationRepo.unreadCount(
          'Bearer ${parentSession.accessToken}',
        );
        expect(count, isA<int>());
      });

      test('public transport search and catalogs are reachable', () async {
        final schools = await catalogRepo.listSchools();
        expect(schools, isA<List<dynamic>>());

        final drivers = await publicTransportRepo.search();
        expect(drivers, isA<List<dynamic>>());
      });

      test(
        'active route lifecycle: start, boarding, disembarking, notifications, '
        'recalculate, telemetry, geofence and finish',
        () async {
          // ── Setup: cria criança e matrícula ativa ──
          dio.options.headers['Authorization'] =
              'Bearer ${parentSession.accessToken}';

          final shifts = await catalogRepo.listShifts();
          final shift = shifts.first;

          final uniqueCpf = _generateCpf();
          final createdChild = await childrenRepo.createChild(
            name: 'Rota Child',
            document: uniqueCpf,
            schoolId: null,
            shiftId: shift.id,
            address: const ChildAddress(
              street: 'Rua Rota',
              number: '100',
              complement: null,
              zipCode: '85851000',
            ),
          );
          final childId = createdChild.id;

          dio.options.headers['Authorization'] =
              'Bearer ${driverSession.accessToken}';
          await driverEnrollmentsRepo.requestEnrollment(childId);

          dio.options.headers['Authorization'] =
              'Bearer ${parentSession.accessToken}';
          final pending = await parentEnrollmentsRepo.getPendingEnrollments();
          final enrollment = pending.firstWhere(
            (e) => e.childId == childId,
            orElse: () => fail('Matrícula pendente não encontrada'),
          );
          await parentEnrollmentsRepo.acceptEnrollment(enrollment.id);

          dio.options.headers['Authorization'] =
              'Bearer ${driverSession.accessToken}';

          // ── Inicia rota ──
          final started = await routesRepo.startRoute();
          expect(started.id, greaterThan(0));
          expect(started.status, RouteStatus.active);
          final routeId = started.id;

          // ── Embarque / desembarque ──
          final boarded = await routesRepo.markBoarding(routeId, childId);
          expect(boarded.status, StopStatus.boarded);

          final disembarked = await routesRepo.markDisembarking(
            routeId,
            childId,
          );
          expect(disembarked.status, StopStatus.disembarked);

          // ── Notificações ──
          await routesRepo.notifyParent(routeId, childId, 'arrived');
          await routesRepo.alertAll(
            routeId,
            message: 'Emergência na rota.',
          );

          dio.options.headers['Authorization'] =
              'Bearer ${parentSession.accessToken}';
          final notifications = await notificationRepo.notifications(
            'Bearer ${parentSession.accessToken}',
          );
          expect(notifications.items, isNotEmpty);

          final first = notifications.items.first;
          await notificationRepo.markAsRead(
            'Bearer ${parentSession.accessToken}',
            first.id,
          );
          await notificationRepo.markAllAsRead(
            'Bearer ${parentSession.accessToken}',
          );
          final unreadCount = await notificationRepo.unreadCount(
            'Bearer ${parentSession.accessToken}',
          );
          expect(unreadCount, equals(0));

          dio.options.headers['Authorization'] =
              'Bearer ${driverSession.accessToken}';

          // ── Recálculo ──
          Response<Map<String, dynamic>> recalcRes;
          try {
            recalcRes = await dio.post<Map<String, dynamic>>(
              '/driver/routes/$routeId/recalculate',
              data: {'lat': -25.5163, 'lng': -54.5854},
            );
          } on DioException catch (e) {
            fail(
              'recalculate failed: ${e.response?.statusCode} ${e.response?.data}',
            );
          }
          expect(recalcRes.statusCode, equals(200));

          // ── Telemetria ──
          Response<Map<String, dynamic>> telemetryRes;
          try {
            telemetryRes = await dio.post<Map<String, dynamic>>(
              '/driver/telemetry/batch',
              data: {
                'routeManifestId': 'route.$routeId',
                'vanId': 1,
                'points': [
                  {
                    'timestamp': DateTime.now().toUtc().toIso8601String(),
                    'lat': -25.5163,
                    'lng': -54.5854,
                    'speed': 30,
                    'heading': 90,
                  },
                ],
              },
            );
          } on DioException catch (e) {
            fail(
              'telemetry failed: ${e.response?.statusCode} ${e.response?.data}',
            );
          }
          expect(telemetryRes.statusCode, anyOf(equals(200), equals(201)));

          // ── Geofence ──
          Response<Map<String, dynamic>> geofenceRes;
          try {
            geofenceRes = await dio.post<Map<String, dynamic>>(
              '/driver/geofences/check',
              data: {
                'lat': -25.5163,
                'lng': -54.5854,
                // Contrato novo: o backend decide o raio por regra (casa 500m
                // / escola 50m) e deriva a rota do token — radiusMeters,
                // limit, routeId e routeManifestId saíram do payload.
              },
            );
          } on DioException catch (e) {
            fail(
              'geofence failed: ${e.response?.statusCode} ${e.response?.data}',
            );
          }
          expect(geofenceRes.statusCode, equals(200));

          // ── Finaliza rota ──
          await routesRepo.finishRoute(routeId);

          final active = await routesRepo.getActiveRoute();
          expect(active, isNull);
        },
        timeout: const Timeout(Duration(minutes: 2)),
      );

      test('device-token endpoint accepts token', () async {
        await notificationRepo.saveDeviceToken(
          'Bearer ${parentSession.accessToken}',
          'fake-device-token-${DateTime.now().millisecondsSinceEpoch}',
        );
      });

      test(
        'publicities impression and click endpoints are reachable',
        () async {
          final response = await dio.get<List<dynamic>>('/publicities');
          expect(response.statusCode, equals(200));

          final ads = response.data ?? [];
          if (ads.isNotEmpty) {
            final firstId = (ads.first as Map<String, dynamic>)['id'] as int;

            final impressionRes = await dio.post<dynamic>(
              '/publicities/$firstId/impression',
            );
            expect(impressionRes.statusCode, equals(204));

            final clickRes = await dio.post<dynamic>(
              '/publicities/$firstId/click',
            );
            expect(clickRes.statusCode, equals(204));
          }
        },
      );

      test(
        'driver profile change request upload-image accepts multipart',
        () async {
          dio.options.headers['Authorization'] =
              'Bearer ${driverSession.accessToken}';

          final tempFile = File(
            '${Directory.systemTemp.path}/avatar_test_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          await tempFile.writeAsBytes(Uint8List.fromList(_minimalPng));
          addTearDown(() async {
            if (await tempFile.exists()) {
              await tempFile.delete();
            }
          });

          final imageUrl = await profileChangeRepo.uploadImage(
            tempFile.path,
            type: 'avatar',
          );
          expect(imageUrl, isNotEmpty);
        },
      );

      test(
        'driver profile change request submit returns pending request',
        () async {
          dio.options.headers['Authorization'] =
              'Bearer ${driverSession.accessToken}';

          final schools = await catalogRepo.listSchools();
          final districts = await catalogRepo.listDistricts();
          final shifts = await catalogRepo.listShifts();

          final schoolIds = schools.isNotEmpty ? [schools.first.id] : <int>[];
          final districtIds = districts.isNotEmpty
              ? [districts.first.id]
              : <int>[];
          final schoolShiftMap = <int, List<int>>{};
          if (schools.isNotEmpty && shifts.isNotEmpty) {
            schoolShiftMap[schools.first.id] = [shifts.first.id];
          }

          final result = await profileChangeRepo.submitRequest(
            schoolIds: schoolIds,
            districtIds: districtIds,
            schoolShiftMap: schoolShiftMap,
            requestNote: 'Solicitação de teste de integração',
          );

          expect(result['status'], equals('pending'));
        },
      );

      test('user avatar upload accepts multipart', () async {
        dio.options.headers['Authorization'] =
            'Bearer ${parentSession.accessToken}';

        final tempFile = File(
          '${Directory.systemTemp.path}/avatar_user_test_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await tempFile.writeAsBytes(Uint8List.fromList(_minimalPng));
        addTearDown(() async {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        });

        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            tempFile.path,
            filename: 'avatar.png',
          ),
        });

        final response = await dio.post<Map<String, dynamic>>(
          '/users/me/avatar',
          data: formData,
        );
        expect(response.statusCode, anyOf(equals(200), equals(201)));

        final body = response.data ?? {};
        final data = body['data'] as Map<String, dynamic>? ?? body;
        expect(
          data['avatar']?.toString().isNotEmpty ??
              data['avatar_url']?.toString().isNotEmpty,
          isTrue,
          reason: 'Esperava avatar ou avatar_url na resposta',
        );
      });

      test(
        'route remove-student and school-bulk-disembark work',
        () async {
          dio.options.headers['Authorization'] =
              'Bearer ${parentSession.accessToken}';

          final shifts = await catalogRepo.listShifts();
          final shift = shifts.first;
          final schools = await catalogRepo.listSchools();
          final school = schools.isNotEmpty ? schools.first : null;
          expect(school, isNotNull, reason: 'Precisa de pelo menos uma escola');

          // Cria duas crianças na mesma escola.
          final cpf1 = _generateCpf();
          final child1 = await childrenRepo.createChild(
            name: 'Aluno Bulk 1',
            document: cpf1,
            schoolId: school!.id,
            shiftId: shift.id,
            address: const ChildAddress(
              street: 'Rua Bulk',
              number: '1',
              complement: null,
              zipCode: '85851000',
            ),
          );

          final cpf2 = _generateCpf();
          final child2 = await childrenRepo.createChild(
            name: 'Aluno Bulk 2',
            document: cpf2,
            schoolId: school.id,
            shiftId: shift.id,
            address: const ChildAddress(
              street: 'Rua Bulk',
              number: '2',
              complement: null,
              zipCode: '85851000',
            ),
          );

          // Motorista solicita matrícula das duas.
          dio.options.headers['Authorization'] =
              'Bearer ${driverSession.accessToken}';
          await driverEnrollmentsRepo.requestEnrollment(child1.id);
          await driverEnrollmentsRepo.requestEnrollment(child2.id);

          // Pai aceita as duas matrículas.
          dio.options.headers['Authorization'] =
              'Bearer ${parentSession.accessToken}';
          var pending = await parentEnrollmentsRepo.getPendingEnrollments();
          for (final childId in [child1.id, child2.id]) {
            final enrollment = pending.firstWhere(
              (e) => e.childId == childId,
              orElse: () => fail('Matrícula pendente não encontrada: $childId'),
            );
            await parentEnrollmentsRepo.acceptEnrollment(enrollment.id);
          }

          // Motorista inicia rota.
          dio.options.headers['Authorization'] =
              'Bearer ${driverSession.accessToken}';
          final started = await routesRepo.startRoute();
          final routeId = started.id;

          // Remove o primeiro aluno da rota.
          await routesRepo.removeStudent(routeId, child1.id);

          // O primeiro aluno deve estar com status removed; o segundo ainda na rota.
          var active = await routesRepo.getActiveRoute();
          expect(active, isNotNull);

          final stop1 = active!.stops.firstWhere(
            (stop) => stop.childId == child1.id,
            orElse: () => fail('Aluno 1 deveria ainda constar na rota'),
          );
          expect(stop1.status, equals(StopStatus.removed));

          final stop2 = active.stops.firstWhere(
            (stop) => stop.childId == child2.id,
            orElse: () => fail('Aluno 2 deveria permanecer na rota'),
          );
          expect(
            stop2.status,
            anyOf(equals(StopStatus.pending), equals(StopStatus.boarded)),
          );

          // Desembarque em massa na escola.
          final disembarked = await routesRepo.bulkDisembarkAtSchool(
            routeId,
            school.id,
          );
          final disembarkedStop2 = disembarked.firstWhere(
            (stop) => stop.childId == child2.id,
            orElse: () => fail('Aluno 2 deveria estar desembarcado'),
          );
          expect(disembarkedStop2.status, equals(StopStatus.disembarked));

          // Finaliza rota.
          await routesRepo.finishRoute(routeId);
        },
        timeout: const Timeout(Duration(minutes: 2)),
      );

      tearDownAll(() async {
        // Garante que nenhuma rota ativa fique pendente entre execuções.
        dio.options.headers['Authorization'] =
            'Bearer ${driverSession.accessToken}';
        try {
          final active = await routesRepo.getActiveRoute();
          if (active != null) {
            await routesRepo.finishRoute(active.id);
          }
        } catch (_) {
          // Ignora falhas de limpeza.
        }
      });
    },
  );
}

int _cpfCounter = 0;

String _generateCpf() {
  _cpfCounter++;
  final random = DateTime.now().millisecondsSinceEpoch + _cpfCounter;
  final base = random
      .toString()
      .padLeft(9, '0')
      .substring(random.toString().length - 9);
  return base + _calcDigit(base) + _calcDigit(base + _calcDigit(base));
}

String _calcDigit(String base) {
  var total = 0;
  for (var i = 0; i < base.length; i++) {
    total += int.parse(base[i]) * (base.length + 1 - i);
  }
  final digit = 11 - (total % 11);
  return digit >= 10 ? '0' : digit.toString();
}

/// PNG 1x1 transparente mínimo para testes de upload.
final List<int> _minimalPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);
