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
///
/// Hoje a busca de transporte é a única superfície que exibe anúncio — para
/// visitante e para usuário logado. Os slots dos dashboards continuam no
/// banco, porém desligados (`ad_placements.is_active = false`), e o feed não
/// os serve.
abstract final class AdPlacements {
  static const searchInlineBanner = 'search-inline-banner';
}

/// Anúncio retornado por `GET /publicities`.
///
/// Contrato do item:
/// `{ id, name, title?, imageUrl, imageKey?, linkUrl?, format, ctaLabel?,
///    weight, placements: string[] }`.
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
    this.imageKey,
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

  /// Chave de versão da imagem enviada pelo backend (`imageKey`): muda
  /// quando o criativo é substituído — base do cache-bust (APP-13).
  final String? imageKey;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  bool get isClickable => linkUrl != null && linkUrl!.trim().isNotEmpty;

  String get displayTitle =>
      title != null && title!.trim().isNotEmpty ? title! : name;

  String get ctaText =>
      ctaLabel != null && ctaLabel!.trim().isNotEmpty ? ctaLabel! : 'Saiba mais';

  /// URL da imagem com cache-bust `?k=<imageKey>` quando o backend informa
  /// `imageKey` (APP-13); caso contrário retorna a URL crua.
  String? get resolvedImageUrl {
    final raw = imageUrl;
    if (raw == null || raw.isEmpty) return null;
    final key = imageKey;
    if (key == null || key.isEmpty) return raw;
    final separator = raw.contains('?') ? '&' : '?';
    return '$raw${separator}k=$key';
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
      imageKey: json['imageKey']?.toString(),
    );
  }
}
