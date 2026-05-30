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
      _cachedLegacyList('schools', '/catalog/schools');

  Future<List<CatalogOption>> listDistricts() =>
      _cachedLegacyList('districts', '/catalog/districts');

  Future<List<CatalogOption>> listShifts() =>
      _cachedLegacyList('shifts', '/catalog/shifts');

  Future<List<CatalogOption>> listRelatives() =>
      _loadPlainList('/catalog/relatives');

  Future<List<CatalogOption>> _cachedLegacyList(
    String cacheKey,
    String path,
  ) async {
    final cached = _loadFromCache(cacheKey);
    if (cached != null) return cached;

    final result = await _loadLegacyList(path);
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
          .map(
            (e) => CatalogOption.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
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
        items.map((e) => <String, dynamic>{'id': e.id, 'name': e.name}).toList(growable: false),
      );
      await _box.put(
        '${key}_at',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

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
