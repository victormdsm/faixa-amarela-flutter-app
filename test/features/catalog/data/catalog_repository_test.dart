import 'dart:io';

import 'package:app_faixa_amarela/features/catalog/data/catalog_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late Directory tempDir;
  late MockDio dio;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = Directory.systemTemp.createTempSync('hive_catalog_test');
    Hive.init(tempDir.path);
    await CatalogRepository.openCacheBox();
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  tearDown(() async {
    final box = Hive.box<dynamic>('catalog_cache');
    await box.clear();
  });

  group('CatalogRepository cache schema versioning', () {
    test('descarta cache de versão antiga e rebusca da rede', () async {
      dio = MockDio();
      final box = Hive.box<dynamic>('catalog_cache');

      // Simula cache legado (schema_version ausente) com escola sem shifts.
      await box.put('schools_at', DateTime.now().millisecondsSinceEpoch);
      await box.put('schools_data', [
        <String, dynamic>{'id': 1, 'name': 'Escola Antiga'},
      ]);

      when(
        () => dio.get<dynamic>('/catalogs/schools'),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          data: [
            <String, dynamic>{
              'id': 1,
              'name': 'Escola Antiga',
              'shifts': [
                <String, dynamic>{'id': 10, 'name': 'Manhã'},
              ],
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/catalogs/schools'),
        ),
      );

      final repo = CatalogRepository(dio);
      final schools = await repo.listSchools();

      expect(schools, hasLength(1));
      expect(schools.first.id, 1);
      expect(schools.first.shifts, hasLength(1));
      expect(schools.first.shifts.first.id, 10);
      expect(schools.first.shifts.first.name, 'Manhã');

      // Garante que a rede foi consultada (cache antigo foi descartado).
      verify(() => dio.get<dynamic>('/catalogs/schools')).called(1);

      // Garante que a versão atual do schema foi gravada.
      expect(box.get('schema_version'), 3);
    });

    test('mantém cache válido quando schema_version está atual', () async {
      dio = MockDio();
      final box = Hive.box<dynamic>('catalog_cache');

      await box.put('schema_version', 3);
      await box.put('schools_at', DateTime.now().millisecondsSinceEpoch);
      await box.put('schools_data', [
        <String, dynamic>{
          'id': 2,
          'name': 'Escola Cache',
          'shifts': [
            <String, dynamic>{'id': 20, 'name': 'Tarde'},
          ],
        },
      ]);

      final repo = CatalogRepository(dio);
      final schools = await repo.listSchools();

      expect(schools, hasLength(1));
      expect(schools.first.id, 2);
      expect(schools.first.shifts.first.name, 'Tarde');

      // Não deve tocar na rede quando o cache ainda é válido.
      verifyNever(() => dio.get<dynamic>('/catalogs/schools'));
    });
  });
}
