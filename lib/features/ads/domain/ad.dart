/// Formatos de anúncio suportados pelo backend (`format` no payload).
enum AdFormat {
  banner('banner'),
  card('card'),
  unknown('');

  const AdFormat(this.wireValue);

  final String wireValue;

  static AdFormat fromWire(String? value) {
    for (final format in AdFormat.values) {
      if (format.wireValue == value) return format;
    }
    return AdFormat.unknown;
  }
}

/// Papel do usuário na superfície onde o anúncio é exibido (`role` na query).
enum AdRole {
  public('public'),
  parent('parent'),
  driver('driver');

  const AdRole(this.wireValue);

  final String wireValue;
}

/// Placements (slots) de anúncio acordados com o backend.
abstract final class AdPlacements {
  static const searchInlineBanner = 'search-inline-banner';
  static const parentDashboardBanner = 'parent-dashboard-banner';
  static const parentDashboardCard = 'parent-dashboard-card';
  static const driverDashboardCard = 'driver-dashboard-card';
}

/// Anúncio retornado por `GET /publicities`.
///
/// Contrato do item:
/// `{ id, name, title?, imageUrl, linkUrl?, format, ctaLabel?, weight,
///    placements: string[] }`.
class Ad {
  const Ad({
    required this.id,
    required this.name,
    this.title,
    this.imageUrl,
    this.linkUrl,
    this.format = AdFormat.unknown,
    this.ctaLabel,
    this.weight = 0,
    this.placements = const <String>[],
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? title;
  final String? imageUrl;
  final String? linkUrl;
  final AdFormat format;
  final String? ctaLabel;
  final int weight;
  final List<String> placements;

  /// Não consta no contrato atual, mas é aceito quando presente para
  /// cache-bust da imagem (ver [resolvedImageUrl]).
  final DateTime? updatedAt;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  bool get isClickable => linkUrl != null && linkUrl!.trim().isNotEmpty;

  String get displayTitle =>
      title != null && title!.trim().isNotEmpty ? title! : name;

  String get ctaText =>
      ctaLabel != null && ctaLabel!.trim().isNotEmpty ? ctaLabel! : 'Saiba mais';

  /// URL da imagem com cache-bust `?v=<updatedAt>` quando o backend informa
  /// `updatedAt`; caso contrário retorna a URL crua.
  String? get resolvedImageUrl {
    final raw = imageUrl;
    if (raw == null || raw.isEmpty) return null;
    final version = updatedAt?.millisecondsSinceEpoch;
    if (version == null) return raw;
    final separator = raw.contains('?') ? '&' : '?';
    return '$raw${separator}v=$version';
  }

  factory Ad.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    int id;
    if (rawId is num) {
      id = rawId.toInt();
    } else if (rawId is String) {
      id = int.tryParse(rawId) ?? 0;
    } else {
      id = 0;
    }

    final rawPlacements = json['placements'];

    return Ad(
      id: id,
      name: json['name']?.toString() ?? '',
      title: json['title']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      // `link` é o nome legado do campo; `linkUrl` é o contrato atual.
      linkUrl: json['linkUrl']?.toString() ?? json['link']?.toString(),
      format: AdFormat.fromWire(json['format']?.toString()),
      ctaLabel: json['ctaLabel']?.toString(),
      weight: (json['weight'] as num?)?.toInt() ?? 0,
      placements: rawPlacements is List
          ? rawPlacements.map((e) => e.toString()).toList(growable: false)
          : const <String>[],
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}
