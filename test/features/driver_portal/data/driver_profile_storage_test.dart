import 'dart:io';

import 'package:app_faixa_amarela/features/driver_portal/data/driver_profile_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

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

  Map<String, dynamic> profile({required int userId, required String name}) =>
      <String, dynamic>{
        'id': userId,
        'userId': userId,
        'name': name,
        'cpf': '12345678900',
        'licenseNumber': '123456789',
        'vanId': 5,
        'vanPlate': 'ABC1234',
        'vanModel': 'Fiat Ducato',
        'vanYear': '2020',
        'coverageArea': 'Norte',
      };

  test('load returns null when cache is empty', () {
    final storage = DriverProfileStorage();
    expect(storage.load(10), isNull);
  });

  test('save and load roundtrip keyed by userId', () async {
    final storage = DriverProfileStorage();

    await storage.save(10, profile(userId: 10, name: 'Motorista Teste'));
    final loaded = storage.load(10);

    expect(loaded, isNotNull);
    expect(loaded!['id'], 10);
    expect(loaded['name'], 'Motorista Teste');
  });

  test('cache is isolated per userId', () async {
    final storage = DriverProfileStorage();

    await storage.save(10, profile(userId: 10, name: 'Usuario A'));
    await storage.save(20, profile(userId: 20, name: 'Usuario B'));

    expect(storage.load(10)!['name'], 'Usuario A');
    expect(storage.load(20)!['name'], 'Usuario B');
    expect(storage.load(30), isNull);
  });

  test('load returns null for invalid cache without id/userId', () async {
    final storage = DriverProfileStorage();
    await storage.save(10, <String, dynamic>{'name': 'Sem id'});

    expect(storage.load(10), isNull);
  });

  test('clear removes cached profiles of every user and the legacy key',
      () async {
    final storage = DriverProfileStorage();
    await storage.save(10, profile(userId: 10, name: 'Usuario A'));
    await storage.save(20, profile(userId: 20, name: 'Usuario B'));
    final box = Hive.box<dynamic>('driver_profile_cache');
    await box.put('profile', profile(userId: 99, name: 'Legado'));
    expect(storage.load(10), isNotNull);
    expect(storage.load(20), isNotNull);

    await storage.clear();

    expect(storage.load(10), isNull);
    expect(storage.load(20), isNull);
    expect(box.get('profile'), isNull);
  });
}
