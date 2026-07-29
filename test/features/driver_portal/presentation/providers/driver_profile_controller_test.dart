import 'dart:io';

import 'package:app_faixa_amarela/domain/models/driver_profile.dart';
import 'package:app_faixa_amarela/domain/repositories/driver_repository.dart';
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

DriverProfile _minimalProfile({required int id, required String name}) {
  return DriverProfile(
    id: id,
    userId: id * 10,
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
      ],
    );
  }

  test(
      'build loads from API and caches when there is no local cache',
      () async {
    final repo = _FakeDriverRepository(_minimalProfile(id: 1, name: 'Joao'));
    final container = createContainer(repo);
    addTearDown(container.dispose);

    final states = <AsyncValue<Map<String, dynamic>>>[];
    container.listen(
      driverProfileProvider,
      (previous, next) => states.add(next),
      fireImmediately: true,
    );

    await pumpEventQueue();
    await Future.delayed(const Duration(milliseconds: 50));

    expect(states, hasLength(2));
    expect(states.first.isLoading, isTrue);
    expect(states.last.hasValue, isTrue);
    expect(states.last.value!['name'], 'Joao');

    expect(repo.callCount, 1);

    final storage = DriverProfileStorage();
    final cached = storage.load();
    expect(cached, isNotNull);
    expect(cached!['name'], 'Joao');
  });

  test(
      'build emits cached data immediately then refreshes from API silently',
      () async {
    final storage = DriverProfileStorage();
    await storage.save(
      _minimalProfile(id: 2, name: 'Cache').toJson(),
    );

    final repo = _FakeDriverRepository(_minimalProfile(id: 2, name: 'API'));
    final container = createContainer(repo);
    addTearDown(container.dispose);

    final states = <AsyncValue<Map<String, dynamic>>>[];
    container.listen(
      driverProfileProvider,
      (previous, next) => states.add(next),
      fireImmediately: true,
    );

    // Aguarda o build concluir e o refresh silencioso terminar.
    await pumpEventQueue();
    await Future.delayed(const Duration(milliseconds: 100));

    final controller = container.read(driverProfileProvider.notifier);

    // Estado final deve refletir a API.
    expect(controller.state.hasValue, isTrue);
    expect(controller.state.value!['name'], 'API');

    // Deve haver pelo menos uma transição que passou pelo cache.
    expect(
      states.any(
        (s) => s.hasValue && s.value!['name'] == 'Cache',
      ),
      isTrue,
    );
    expect(repo.callCount, 1);
  });

  test('refresh forces a new API call and updates cache', () async {
    final storage = DriverProfileStorage();
    await storage.save(
      _minimalProfile(id: 3, name: 'Antigo').toJson(),
    );

    final repo = _FakeDriverRepository(_minimalProfile(id: 3, name: 'Novo'));
    final container = createContainer(repo);
    addTearDown(container.dispose);

    final controller = container.read(driverProfileProvider.notifier);
    await pumpEventQueue();

    await controller.refresh();

    expect(controller.state.hasValue, isTrue);
    expect(controller.state.value!['name'], 'Novo');
    expect(repo.callCount, 2); // build + refresh

    final cached = storage.load();
    expect(cached, isNotNull);
    expect(cached!['name'], 'Novo');
  });

  test('silent refresh keeps cache when API fails', () async {
    final storage = DriverProfileStorage();
    await storage.save(
      _minimalProfile(id: 4, name: 'Local').toJson(),
    );

    final repo = _FakeDriverRepository(null);
    final container = createContainer(repo);
    addTearDown(container.dispose);

    // Mantém listener ativo para impedir dispose do provider durante o teste.
    container.listen(driverProfileProvider, (previous, next) {});

    final controller = container.read(driverProfileProvider.notifier);

    // Aguarda o build concluir com o cache.
    await pumpEventQueue();

    // Cache imediato.
    expect(controller.state.hasValue, isTrue);
    expect(controller.state.value!['name'], 'Local');

    // Aguarda o refresh silencioso falhar sem alterar o estado.
    await pumpEventQueue();
    await Future.delayed(const Duration(milliseconds: 100));

    expect(controller.state.hasValue, isTrue);
    expect(controller.state.value!['name'], 'Local');
  });
}
