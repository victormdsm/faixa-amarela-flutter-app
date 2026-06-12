import 'package:app_faixa_amarela/features/catalog/data/catalog_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CatalogRepository E2E (producao)', () {
    late Dio dio;
    late CatalogRepository repo;

    setUp(() {
      dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.faixaamarela.com.br/api/v1',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      repo = CatalogRepository(dio);
    });

    test('listSchools retorna opcoes com id numerico e nome', () async {
      final schools = await repo.listSchools();
      expect(schools, isNotEmpty);
      expect(schools.first.id, greaterThan(0));
      expect(schools.first.name, isNotEmpty);
      print('Escolas carregadas: ${schools.length}');
      print('Primeira: ${schools.first.id} - ${schools.first.name}');
    });

    test('listDistricts retorna opcoes com id numerico e nome', () async {
      final districts = await repo.listDistricts();
      expect(districts, isNotEmpty);
      expect(districts.first.id, greaterThan(0));
      expect(districts.first.name, isNotEmpty);
      print('Bairros carregados: ${districts.length}');
      print('Primeiro: ${districts.first.id} - ${districts.first.name}');
    });

    test('listShifts retorna opcoes com id numerico e nome', () async {
      final shifts = await repo.listShifts();
      expect(shifts, isNotEmpty);
      expect(shifts.first.id, greaterThan(0));
      expect(shifts.first.name, isNotEmpty);
      print('Turnos carregados: ${shifts.length}');
      print('Primeiro: ${shifts.first.id} - ${shifts.first.name}');
    });
  });
}
