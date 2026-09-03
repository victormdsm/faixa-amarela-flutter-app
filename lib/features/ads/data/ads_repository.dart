import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  /// Busca os anúncios do [placement].
  ///
  /// [cityId] vem da superfície (na busca, da escola/bairro escolhido). Sem
  /// cidade o backend só devolve anúncios sem segmentação geográfica — um
  /// anúncio comprado para uma cidade não vaza para o resto do país.
  Future<List<Ad>> fetchAds({
    required String placement,
    required AdRole role,
    String? deviceId,
    int? cityId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/publicities',
        queryParameters: <String, dynamic>{
          'placement': placement,
          'role': role.wireValue,
          'device_id': deviceId ?? await _deviceIdStorage.getOrCreate(),
          'city_id': ?cityId,
        },
      );
      return _parseAds(response.data);
    } catch (e) {
      debugPrint('[AdsRepository.fetchAds] falhou ($placement): $e');
      return const [];
    }
  }

  /// Registra impressão no máximo 1× por anúncio por placement por sessão.
  Future<void> trackImpression(
    int adId, {
    String? placement,
    String? surface,
    AdRole? role,
    String? deviceId,
    int? cityId,
  }) async {
    final key = '${placement ?? ''}:$adId';
    if (!_impressionsSent.add(key)) return;
    await _track(
      adId,
      'impression',
      placement: placement,
      surface: surface,
      role: role,
      deviceId: deviceId,
      cityId: cityId,
    );
  }

  Future<void> trackClick(
    int adId, {
    String? placement,
    String? surface,
    AdRole? role,
    String? deviceId,
    int? cityId,
  }) async {
    await _track(
      adId,
      'click',
      placement: placement,
      surface: surface,
      role: role,
      deviceId: deviceId,
      cityId: cityId,
    );
  }

  Future<void> _track(
    int adId,
    String event, {
    String? placement,
    String? surface,
    AdRole? role,
    String? deviceId,
    int? cityId,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/publicities/$adId/$event',
        data: <String, dynamic>{
          'placement': ?placement,
          'surface': ?surface,
          // APP-25: o backend grava audience_role a partir deste campo.
          'role': ?role?.wireValue,
          'deviceId': deviceId ?? await _deviceIdStorage.getOrCreate(),
          'cityId': ?cityId,
        },
      );
    } catch (e) {
      // Endpoint de métrica: não crítico.
      debugPrint('[AdsRepository._track] $event/$adId falhou: $e');
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
