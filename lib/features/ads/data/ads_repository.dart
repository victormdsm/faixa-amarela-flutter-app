import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/storage/device_id_storage.dart';
import '../domain/ad.dart';

final adsRepositoryProvider = Provider<AdsRepository>(
  (ref) => AdsRepository(ref.watch(dioProvider)),
);

/// Acesso a anúncios e métricas (`/publicities`).
///
/// Anúncio nunca quebra a tela: qualquer falha de rede/parse resulta em
/// lista vazia ou é simplesmente engolida (tracking).
class AdsRepository {
  AdsRepository(this._dio, {DeviceIdStorage? deviceIdStorage})
    : _deviceIdStorage = deviceIdStorage ?? DeviceIdStorage();

  final Dio _dio;
  final DeviceIdStorage _deviceIdStorage;

  /// Dedup de impressões da sessão: `<placement>:<adId>`.
  final Set<String> _impressionsSent = <String>{};

  Future<List<Ad>> fetchAds({
    required String placement,
    required AdRole role,
    String? deviceId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/publicities',
        queryParameters: <String, dynamic>{
          'placement': placement,
          'role': role.wireValue,
          'device_id': deviceId ?? await _deviceIdStorage.getOrCreate(),
        },
      );
      return _parseAds(response.data);
    } catch (_) {
      return const [];
    }
  }

  /// Registra impressão no máximo 1× por anúncio por placement por sessão.
  Future<void> trackImpression(
    int adId, {
    String? placement,
    String? surface,
    String? deviceId,
  }) async {
    final key = '${placement ?? ''}:$adId';
    if (!_impressionsSent.add(key)) return;
    await _track(
      adId,
      'impression',
      placement: placement,
      surface: surface,
      deviceId: deviceId,
    );
  }

  Future<void> trackClick(
    int adId, {
    String? placement,
    String? surface,
    String? deviceId,
  }) async {
    await _track(
      adId,
      'click',
      placement: placement,
      surface: surface,
      deviceId: deviceId,
    );
  }

  Future<void> _track(
    int adId,
    String event, {
    String? placement,
    String? surface,
    String? deviceId,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/publicities/$adId/$event',
        data: <String, dynamic>{
          'placement': ?placement,
          'surface': ?surface,
          'deviceId': deviceId ?? await _deviceIdStorage.getOrCreate(),
        },
      );
    } catch (_) {
      // Endpoint de métrica: não crítico.
    }
  }

  /// Aceita tanto a lista direta (após o unwrap do
  /// [NestjsResponseUnwrapInterceptor]) quanto o envelope `{ data: [...] }`
  /// (preservado quando há `meta`).
  List<Ad> _parseAds(dynamic raw) {
    final List<dynamic> items;
    if (raw is List) {
      items = raw;
    } else if (raw is Map && raw['data'] is List) {
      items = raw['data'] as List<dynamic>;
    } else {
      return const [];
    }

    return items
        .whereType<Map>()
        .map((e) => Ad.fromJson(Map<String, dynamic>.from(e)))
        .where((ad) => ad.id > 0 && ad.hasImage)
        .toList(growable: false);
  }
}
