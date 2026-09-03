import 'package:app_faixa_amarela/features/ads/data/ads_repository.dart';
import 'package:app_faixa_amarela/features/ads/domain/ad.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

Response<dynamic> _jsonResponse(dynamic data, String path) {
  return Response<dynamic>(
    data: data,
    statusCode: 200,
    requestOptions: RequestOptions(path: path),
  );
}

const _adJson = <String, dynamic>{
  'id': 7,
  'name': 'Campanha',
  'title': 'Matrículas abertas',
  'imageUrl': 'https://cdn.example.com/banner.png',
  'linkUrl': 'https://example.com/promo',
  'format': 'banner',
  'ctaLabel': 'Aproveite',
  'weight': 5,
  'placements': <String>['search-inline-banner'],
};

void main() {
  late MockDio dio;
  late AdsRepository repository;

  setUp(() {
    dio = MockDio();
    repository = AdsRepository(dio);
  });

  group('fetchAds', () {
    test('parses a plain list (response after envelope unwrap)', () async {
      when(
        () => dio.get<dynamic>(
          '/publicities',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => _jsonResponse(const [_adJson], '/publicities'));

      final ads = await repository.fetchAds(
        placement: AdPlacements.searchInlineBanner,
        role: AdRole.public,
        deviceId: 'device-1',
      );

      expect(ads, hasLength(1));
      expect(ads.single.id, 7);
      expect(ads.single.linkUrl, 'https://example.com/promo');
      expect(ads.single.format, AdFormat.banner);
    });

    test('parses the { data: [...] } envelope when meta is present', () async {
      when(
        () => dio.get<dynamic>(
          '/publicities',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => _jsonResponse(<String, dynamic>{
          'data': const [_adJson],
          'meta': <String, dynamic>{'total': 1},
        }, '/publicities'),
      );

      final ads = await repository.fetchAds(
        placement: AdPlacements.searchInlineBanner,
        role: AdRole.parent,
        deviceId: 'device-1',
      );

      expect(ads, hasLength(1));
      expect(ads.single.name, 'Campanha');
    });

    test('sends placement, role, device_id and city_id as query parameters',
        () async {
      when(
        () => dio.get<dynamic>(
          '/publicities',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => _jsonResponse(const [], '/publicities'));

      await repository.fetchAds(
        placement: AdPlacements.searchInlineBanner,
        role: AdRole.driver,
        deviceId: 'device-9',
        cityId: 42,
      );

      final captured = verify(
        () => dio.get<dynamic>(
          '/publicities',
          queryParameters: captureAny(named: 'queryParameters'),
        ),
      ).captured;

      final params = captured.single as Map<String, dynamic>;
      expect(params['placement'], AdPlacements.searchInlineBanner);
      expect(params['role'], 'driver');
      expect(params['device_id'], 'device-9');
      expect(params['city_id'], 42);
    });

    test('omits city_id when the surface has no city', () async {
      when(
        () => dio.get<dynamic>(
          '/publicities',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => _jsonResponse(const [], '/publicities'));

      await repository.fetchAds(
        placement: AdPlacements.searchInlineBanner,
        role: AdRole.public,
        deviceId: 'device-9',
      );

      final captured = verify(
        () => dio.get<dynamic>(
          '/publicities',
          queryParameters: captureAny(named: 'queryParameters'),
        ),
      ).captured;

      final params = captured.single as Map<String, dynamic>;
      expect(params.containsKey('city_id'), isFalse);
    });

    test('drops items without image or with invalid id', () async {
      when(
        () => dio.get<dynamic>(
          '/publicities',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => _jsonResponse(const [
          _adJson,
          <String, dynamic>{'id': 8, 'name': 'sem imagem'},
          <String, dynamic>{
            'id': 0,
            'name': 'id inválido',
            'imageUrl': 'https://cdn.example.com/x.png',
          },
        ], '/publicities'),
      );

      final ads = await repository.fetchAds(
        placement: AdPlacements.searchInlineBanner,
        role: AdRole.public,
        deviceId: 'device-1',
      );

      expect(ads, hasLength(1));
      expect(ads.single.id, 7);
    });

    test('fails silently returning an empty list', () async {
      when(
        () => dio.get<dynamic>(
          '/publicities',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/publicities')),
      );

      final ads = await repository.fetchAds(
        placement: AdPlacements.searchInlineBanner,
        role: AdRole.public,
        deviceId: 'device-1',
      );

      expect(ads, isEmpty);
    });
  });

  group('trackImpression', () {
    test('posts placement/surface/deviceId body once per ad per placement',
        () async {
      when(
        () => dio.post<dynamic>(
          '/publicities/7/impression',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => _jsonResponse(null, '/publicities/7/impression'),
      );

      await repository.trackImpression(
        7,
        placement: AdPlacements.searchInlineBanner,
        surface: 'banner',
        deviceId: 'device-1',
      );
      // Segunda chamada: mesmo anúncio + placement → dedup, sem novo POST.
      await repository.trackImpression(
        7,
        placement: AdPlacements.searchInlineBanner,
        surface: 'banner',
        deviceId: 'device-1',
      );

      final captured = verify(
        () => dio.post<dynamic>(
          '/publicities/7/impression',
          data: captureAny(named: 'data'),
        ),
      ).captured;

      expect(captured, hasLength(1));
      expect(
        captured.single,
        equals(const <String, dynamic>{
          'placement': 'search-inline-banner',
          'surface': 'banner',
          'deviceId': 'device-1',
        }),
      );
    });

    test('same ad on a different placement sends a new impression', () async {
      when(
        () => dio.post<dynamic>(
          '/publicities/7/impression',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => _jsonResponse(null, '/publicities/7/impression'),
      );

      await repository.trackImpression(
        7,
        placement: AdPlacements.searchInlineBanner,
        deviceId: 'device-1',
      );
      await repository.trackImpression(
        7,
        placement: 'outro-slot',
        deviceId: 'device-1',
      );

      verify(
        () => dio.post<dynamic>(
          '/publicities/7/impression',
          data: any(named: 'data'),
        ),
      ).called(2);
    });

    test('fails silently', () async {
      when(
        () => dio.post<dynamic>(
          '/publicities/7/impression',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/publicities/7/impression'),
        ),
      );

      await repository.trackImpression(7, deviceId: 'device-1');
    });
  });

  group('trackClick', () {
    test('posts to the click endpoint with placement/surface/deviceId/cityId',
        () async {
      when(
        () => dio.post<dynamic>('/publicities/7/click', data: any(named: 'data')),
      ).thenAnswer((_) async => _jsonResponse(null, '/publicities/7/click'));

      await repository.trackClick(
        7,
        placement: AdPlacements.searchInlineBanner,
        surface: 'card',
        deviceId: 'device-2',
        cityId: 42,
      );

      final captured = verify(
        () => dio.post<dynamic>(
          '/publicities/7/click',
          data: captureAny(named: 'data'),
        ),
      ).captured;

      expect(
        captured.single,
        equals(const <String, dynamic>{
          'placement': 'search-inline-banner',
          'surface': 'card',
          'deviceId': 'device-2',
          'cityId': 42,
        }),
      );
    });

    test('is not deduplicated', () async {
      when(
        () => dio.post<dynamic>('/publicities/7/click', data: any(named: 'data')),
      ).thenAnswer((_) async => _jsonResponse(null, '/publicities/7/click'));

      await repository.trackClick(7, deviceId: 'device-1');
      await repository.trackClick(7, deviceId: 'device-1');

      verify(
        () => dio.post<dynamic>('/publicities/7/click', data: any(named: 'data')),
      ).called(2);
    });

    test('fails silently', () async {
      when(
        () => dio.post<dynamic>('/publicities/7/click', data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/publicities/7/click'),
        ),
      );

      await repository.trackClick(7, deviceId: 'device-1');
    });
  });
}
