import 'dart:io';

import 'package:app_faixa_amarela/core/network/api_exception.dart';
import 'package:app_faixa_amarela/domain/models/driver_profile.dart';
import 'package:app_faixa_amarela/domain/repositories/driver_repository.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_session.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_user.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/user_role.dart';
import 'package:app_faixa_amarela/features/auth/presentation/state/app_session_controller.dart';
import 'package:app_faixa_amarela/features/auth/presentation/state/app_session_state.dart';
import 'package:app_faixa_amarela/features/driver_portal/data/driver_profile_storage.dart';
import 'package:app_faixa_amarela/features/driver_portal/presentation/providers/driver_portal_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

class _FakeDriverRepository implements DriverRepository {
  _FakeDriverRepository(this._profile);

  DriverProfile? _profile;
  int callCount = 0;

  @override
  Future<DriverProfile?> getDriverProfile() async {
    callCount++;
    return _profile;
  }

  @override
  Future<DriverProfile> updateBasicProfile({
    required String name,
    String? email,
    String? cellPhone,
    String? information,
    String? cnh,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> updateMyVehicle({
    required String plate,
    String? brand,
    String? color,
    String? year,
  }) async {
    throw UnimplementedError();
  }

  void setProfile(DriverProfile? profile) => _profile = profile;
}

class _FakeAppSessionController extends AppSessionController {
  _FakeAppSessionController(this.userId);

  final int userId;

  @override
  AppSessionState build() {
    return AppSessionState(
      session: AuthSession(
        accessToken: 'tok',
        tokenType: 'Bearer',
        user: AuthUser(
          id: userId,
          name: 'Motorista',
          email: null,
          roles: const ['driver'],
        ),
      ),
      isLoading: false,
      loginRole: UserRole.driver,
    );
  }
}

DriverProfile _minimalProfile({required int userId, required String name}) {
  return DriverProfile(
    id: userId,
    userId: userId,
    name: name,
    cpf: '12345678900',
    licenseNumber: '123456789',
    vanId: 1,
    vanPlate: 'ABC1234',
    vanModel: 'Fiat Ducato',
    vanYear: '2020',
    coverageArea: 'Norte',
  );
}

void main() {
  const userId = 10;
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = Directory.systemTemp.createTempSync('hive_driver_profile_test');
    Hive.init(tempDir.path);
    await DriverProfileStorage.openBox();
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  tearDown(() async {
    final box = Hive.box<dynamic>('driver_profile_cache');
    await box.clear();
  });

  ProviderContainer createContainer(_FakeDriverRepository repo) {
    return ProviderContainer(
      overrides: [
        driverProfileRepositoryProvider.overrideWithValue(repo),
        appSessionControllerProvider.overrideWith(
          () => _FakeAppSessionController(userId),
        ),
      ],
    );
  }

  test('first build without cache fetches from API and writes the cache',
      () async {
    final repo = _FakeDriverRepository(
      _minimalProfile(userId: userId, name: 'Joao'),
    );
    final container = createContainer(repo);
    addTearDown(container.dispose);

    container.listen(driverProfileProvider, (previous, next) {});
    await pumpEventQueue();

    final state = container.read(driverProfileProvider);
    expect(state.hasValue, isTrue);
    expect(state.value!['name'], 'Joao');
    expect(repo.callCount, 1);

    final cached = DriverProfileStorage().load(userId);
    expect(cached, isNotNull);
    expect(cached!['name'], 'Joao');
  });

  test('build with cache shows cached data immediately WITHOUT calling the API',
      () async {
    final storage = DriverProfileStorage();
    await storage.save(
      userId,
      _minimalProfile(userId: userId, name: 'Cache').toJson(),
    );

    final repo = _FakeDriverRepository(
      _minimalProfile(userId: userId, name: 'API'),
    );
    final container = createContainer(repo);
    addTearDown(container.dispose);

    container.listen(driverProfileProvider, (previous, next) {});
    await pumpEventQueue();
    // Garante que nenhum fetch assíncrono tardio foi disparado.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final state = container.read(driverProfileProvider);
    expect(state.hasValue, isTrue);
    expect(state.value!['name'], 'Cache');
    // Sem auto-refetch: a API não pode ser chamada na abertura com cache.
    expect(repo.callCount, 0);

    final guard = container.read(driverProfileSessionGuardProvider);
    expect(guard.loadedUserId, userId);
  });

  test('manual refresh calls the API and updates state and cache', () async {
    final storage = DriverProfileStorage();
    await storage.save(
      userId,
      _minimalProfile(userId: userId, name: 'Antigo').toJson(),
    );

    final repo = _FakeDriverRepository(
      _minimalProfile(userId: userId, name: 'Novo'),
    );
    final container = createContainer(repo);
    addTearDown(container.dispose);

    container.listen(driverProfileProvider, (previous, next) {});
    await pumpEventQueue();
    expect(repo.callCount, 0); // abertura servida pelo cache

    final controller = container.read(driverProfileProvider.notifier);
    await controller.refresh();

    expect(repo.callCount, 1);
    expect(controller.state.hasValue, isTrue);
    expect(controller.state.value!['name'], 'Novo');

    final cached = storage.load(userId);
    expect(cached, isNotNull);
    expect(cached!['name'], 'Novo');
  });

  test('failed manual refresh keeps cached data on screen and rethrows',
      () async {
    final storage = DriverProfileStorage();
    await storage.save(
      userId,
      _minimalProfile(userId: userId, name: 'Local').toJson(),
    );

    final repo = _FakeDriverRepository(null);
    final container = createContainer(repo);
    addTearDown(container.dispose);

    container.listen(driverProfileProvider, (previous, next) {});
    await pumpEventQueue();

    final controller = container.read(driverProfileProvider.notifier);
    expect(controller.state.value!['name'], 'Local');

    await expectLater(
      controller.refresh(),
      throwsA(isA<ApiException>()),
    );

    // Estado intocado: o cache segue visível (requisito: não zerar o form).
    expect(controller.state.hasValue, isTrue);
    expect(controller.state.value!['name'], 'Local');
    expect(repo.callCount, 1);
  });

  test('invalidation after load (push event) refetches from the API',
      () async {
    final storage = DriverProfileStorage();
    await storage.save(
      userId,
      _minimalProfile(userId: userId, name: 'Cache').toJson(),
    );

    final repo = _FakeDriverRepository(
      _minimalProfile(userId: userId, name: 'API'),
    );
    final container = createContainer(repo);
    addTearDown(container.dispose);

    container.listen(driverProfileProvider, (previous, next) {});
    await pumpEventQueue();
    expect(repo.callCount, 0);

    // Simula o push driver_profile_change_reviewed (app.dart invalida o
    // provider): é evento explícito, então busca dados frescos.
    container.refresh(driverProfileProvider);
    final value = await container.read(driverProfileProvider.future);

    expect(repo.callCount, 1);
    expect(value['name'], 'API');
  });

  test('invalidation falling back to cache when the API fails', () async {
    final storage = DriverProfileStorage();
    await storage.save(
      userId,
      _minimalProfile(userId: userId, name: 'Local').toJson(),
    );

    final repo = _FakeDriverRepository(null);
    final container = createContainer(repo);
    addTearDown(container.dispose);

    container.listen(driverProfileProvider, (previous, next) {});
    await pumpEventQueue();
    expect(repo.callCount, 0);

    container.refresh(driverProfileProvider);
    final value = await container.read(driverProfileProvider.future);

    expect(repo.callCount, 1);
    expect(value['name'], 'Local');
  });

  test('cache of another user is ignored', () async {
    final storage = DriverProfileStorage();
    await storage.save(
      999,
      _minimalProfile(userId: 999, name: 'Outro Usuario').toJson(),
    );

    final repo = _FakeDriverRepository(
      _minimalProfile(userId: userId, name: 'Da API'),
    );
    final container = createContainer(repo);
    addTearDown(container.dispose);

    container.listen(driverProfileProvider, (previous, next) {});
    await pumpEventQueue();

    final state = container.read(driverProfileProvider);
    expect(state.value!['name'], 'Da API');
    expect(repo.callCount, 1);
    expect(storage.load(userId)!['name'], 'Da API');
    // Cache do outro usuário permanece intacto.
    expect(storage.load(999)!['name'], 'Outro Usuario');
  });
}
