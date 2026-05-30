import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/catalog_option.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/network_providers.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(dioProvider)),
);

final schoolsCatalogProvider = FutureProvider<List<CatalogOption>>((ref) async {
  return ref.watch(catalogRepositoryProvider).listSchools();
});

final districtsCatalogProvider = FutureProvider<List<CatalogOption>>((
  ref,
) async {
  return ref.watch(catalogRepositoryProvider).listDistricts();
});

final shiftsCatalogProvider = FutureProvider<List<CatalogOption>>((ref) async {
  return ref.watch(catalogRepositoryProvider).listShifts();
});

final relativesCatalogProvider = FutureProvider<List<CatalogOption>>((
  ref,
) async {
  return ref.watch(catalogRepositoryProvider).listRelatives();
});

class CatalogRepository {
  CatalogRepository(this._dio);

  final Dio _dio;

  Future<List<CatalogOption>> listSchools() =>
      _loadLegacyList('/catalog/schools');

  Future<List<CatalogOption>> listDistricts() =>
      _loadLegacyList('/catalog/districts');

  Future<List<CatalogOption>> listShifts() =>
      _loadLegacyList('/catalog/shifts');

  Future<List<CatalogOption>> listRelatives() =>
      _loadPlainList('/catalog/relatives');

  Future<List<CatalogOption>> _loadLegacyList(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: const {'hide_paginate': 1, 'total_pages': 3000},
      );

      final root = response.data ?? const <String, dynamic>{};
      final raw = root['data'];
      final list = raw is List ? raw : const <dynamic>[];

      return list
          .whereType<Map>()
          .map((e) => CatalogOption.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id > 0 && e.name.trim().isNotEmpty)
          .toList(growable: false);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<CatalogOption>> _loadPlainList(String path) async {
    try {
      final response = await _dio.get<List<dynamic>>(path);
      final raw = response.data ?? const <dynamic>[];
      return raw
          .whereType<Map>()
          .map((e) {
            final json = Map<String, dynamic>.from(e);
            if ((json['name'] ?? '').toString().trim().isEmpty &&
                json['relative'] != null) {
              json['name'] = json['relative'];
            }
            return CatalogOption.fromJson(json);
          })
          .where((e) => e.id > 0 && e.name.trim().isNotEmpty)
          .toList(growable: false);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
