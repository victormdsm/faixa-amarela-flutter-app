import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

final citiesCatalogProvider = FutureProvider<List<CatalogOption>>((ref) async {
  return ref.watch(catalogRepositoryProvider).listCities();
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

  static const _boxName = 'catalog_cache';
  static const _ttlMs = 24 * 60 * 60 * 1000; // 24 hours

  static Future<void> openCacheBox() => Hive.openBox<dynamic>(_boxName);

  Box<dynamic> get _box => Hive.box<dynamic>(_boxName);

  Future<List<CatalogOption>> listSchools() =>
      _cachedList('schools', '/catalogs/schools');

  Future<List<CatalogOption>> listDistricts() =>
      _cachedList('districts', '/catalogs/districts');

  Future<List<CatalogOption>> listShifts() =>
      _cachedList('shifts', '/catalogs/shifts');

  Future<List<CatalogOption>> listRelatives() =>
      _loadPlainList('/catalogs/relatives');

  Future<List<CatalogOption>> listPlans() =>
      _cachedList('plans', '/catalogs/plans');

  Future<List<CatalogOption>> listCities() =>
      _cachedList('cities', '/catalogs/cities');

  Future<List<CatalogOption>> listProvinces() =>
      _cachedList('provinces', '/catalogs/provinces');

  Future<List<CatalogOption>> _cachedList(String cacheKey, String path) async {
    final cached = _loadFromCache(cacheKey);
    if (cached != null) return cached;

    final result = await _loadList(path);
    await _saveToCache(cacheKey, result);
    return result;
  }

  List<CatalogOption>? _loadFromCache(String key) {
    try {
      final fetchedAt = _box.get('${key}_at') as int?;
      if (fetchedAt == null) return null;
      if (DateTime.now().millisecondsSinceEpoch - fetchedAt > _ttlMs) {
        return null;
      }
      final raw = _box.get('${key}_data') as List?;
      if (raw == null) return null;
      return raw
          .whereType<Map>()
          .map((e) => CatalogOption.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id > 0 && e.name.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache(String key, List<CatalogOption> items) async {
    try {
      await _box.put(
        '${key}_data',
        items
            .map((e) => <String, dynamic>{'id': e.id, 'name': e.name})
            .toList(growable: false),
      );
      await _box.put('${key}_at', DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<List<CatalogOption>> _loadList(String path) async {
    try {
      final response = await _dio.get<dynamic>(path);
      final raw = _unwrapList(response.data);

      return raw
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
      final response = await _dio.get<dynamic>(path);
      final raw = _unwrapList(response.data);
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

  /// Extrai a lista do envelope { data: [...] } do NestJS ou retorna a lista
  /// direta caso o contrato mude.
  List<dynamic> _unwrapList(dynamic response) {
    if (response == null) return const [];
    if (response is List) return response;
    final data = response['data'];
    if (data is List) return data;
    return const [];
  }
}
