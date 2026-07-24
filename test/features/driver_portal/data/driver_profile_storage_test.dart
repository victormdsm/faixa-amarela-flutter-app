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

  test('load returns null when cache is empty', () {
    final storage = DriverProfileStorage();
    expect(storage.load(), isNull);
  });

  test('save and load roundtrip', () async {
    final storage = DriverProfileStorage();
    final profile = <String, dynamic>{
      'id': 1,
      'userId': 10,
      'name': 'Motorista Teste',
      'cpf': '12345678900',
      'licenseNumber': '123456789',
      'vanId': 5,
      'vanPlate': 'ABC1234',
      'vanModel': 'Fiat Ducato',
      'vanYear': '2020',
      'coverageArea': 'Norte',
    };

    await storage.save(profile);
    final loaded = storage.load();

    expect(loaded, isNotNull);
    expect(loaded!['id'], 1);
    expect(loaded['name'], 'Motorista Teste');
  });

  test('load returns null for invalid cache without id/userId', () async {
    final storage = DriverProfileStorage();
    await storage.save(<String, dynamic>{'name': 'Sem id'});

    expect(storage.load(), isNull);
  });

  test('clear removes cached profile', () async {
    final storage = DriverProfileStorage();
    await storage.save(<String, dynamic>{'id': 1, 'name': 'Teste'});
    expect(storage.load(), isNotNull);

    await storage.clear();
    expect(storage.load(), isNull);
  });
}
