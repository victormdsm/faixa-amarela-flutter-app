import 'package:app_faixa_amarela/features/ads/domain/ad.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ad.fromJson', () {
    test('parses the full backend contract item', () {
      final ad = Ad.fromJson(const <String, dynamic>{
        'id': 7,
        'name': 'Campanha Volta às Aulas',
        'title': 'Matrículas abertas',
        'imageUrl': 'https://cdn.example.com/banner.png',
        'linkUrl': 'https://example.com/promo',
        'format': 'banner',
        'ctaLabel': 'Aproveite',
        'weight': 5,
        'placements': <String>['search-inline-banner'],
      });

      expect(ad.id, 7);
      expect(ad.name, 'Campanha Volta às Aulas');
      expect(ad.title, 'Matrículas abertas');
      expect(ad.imageUrl, 'https://cdn.example.com/banner.png');
      expect(ad.linkUrl, 'https://example.com/promo');
      expect(ad.format, AdFormat.banner);
      expect(ad.ctaLabel, 'Aproveite');
      expect(ad.weight, 5);
      expect(ad.placements, <String>['search-inline-banner']);
      expect(ad.isClickable, isTrue);
      expect(ad.hasImage, isTrue);
    });

    test('accepts numeric id serialized as string', () {
      final ad = Ad.fromJson(const <String, dynamic>{
        'id': '42',
        'name': 'x',
        'imageUrl': 'https://cdn.example.com/a.png',
      });
      expect(ad.id, 42);
    });

    test('falls back to legacy `link` when `linkUrl` is absent', () {
      final ad = Ad.fromJson(const <String, dynamic>{
        'id': 1,
        'name': 'x',
        'imageUrl': 'https://cdn.example.com/a.png',
        'link': 'https://example.com/legacy',
      });
      expect(ad.linkUrl, 'https://example.com/legacy');
    });

    test('parses format card and unknown formats safely', () {
      final card = Ad.fromJson(const <String, dynamic>{
        'id': 1,
        'name': 'x',
        'imageUrl': 'https://cdn.example.com/a.png',
        'format': 'card',
      });
      expect(card.format, AdFormat.card);

      final other = Ad.fromJson(const <String, dynamic>{
        'id': 1,
        'name': 'x',
        'imageUrl': 'https://cdn.example.com/a.png',
        'format': 'interstitial',
      });
      expect(other.format, AdFormat.unknown);

      final missing = Ad.fromJson(const <String, dynamic>{
        'id': 1,
        'name': 'x',
        'imageUrl': 'https://cdn.example.com/a.png',
      });
      expect(missing.format, AdFormat.unknown);
    });

    test('displayTitle falls back to name and ctaText to "Saiba mais"', () {
      final ad = Ad.fromJson(const <String, dynamic>{
        'id': 1,
        'name': 'Nome interno',
        'imageUrl': 'https://cdn.example.com/a.png',
      });
      expect(ad.displayTitle, 'Nome interno');
      expect(ad.ctaText, 'Saiba mais');
      expect(ad.isClickable, isFalse);
    });

    test('resolvedImageUrl adds cache-bust only when imageKey is present', () {
      final withoutImageKey = Ad.fromJson(const <String, dynamic>{
        'id': 1,
        'name': 'x',
        'imageUrl': 'https://cdn.example.com/a.png',
      });
      expect(
        withoutImageKey.resolvedImageUrl,
        'https://cdn.example.com/a.png',
      );

      final withImageKey = Ad.fromJson(const <String, dynamic>{
        'id': 1,
        'name': 'x',
        'imageUrl': 'https://cdn.example.com/a.png',
        'imageKey': 'banner-v2',
      });
      expect(
        withImageKey.resolvedImageUrl,
        'https://cdn.example.com/a.png?k=banner-v2',
      );

      final withQueryAndImageKey = Ad.fromJson(const <String, dynamic>{
        'id': 1,
        'name': 'x',
        'imageUrl': 'https://cdn.example.com/a.png?w=800',
        'imageKey': 'banner-v2',
      });
      expect(
        withQueryAndImageKey.resolvedImageUrl,
        'https://cdn.example.com/a.png?w=800&k=banner-v2',
      );
    });
  });
}
