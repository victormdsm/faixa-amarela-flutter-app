/// Sugestão de endereço retornada pelo autocomplete ou pelo reverse
/// geocoding (`GET /parent/addresses/autocomplete|reverse`).
///
/// Campos estruturados (street/number/district/city/state) são opcionais:
/// o provedor de geocoding nem sempre consegue decompor o endereço.
class AddressSuggestion {
  const AddressSuggestion({
    required this.label,
    this.street,
    this.number,
    this.district,
    this.city,
    this.state,
    this.latitude,
    this.longitude,
  });

  /// Endereço formatado para exibição (ex.: "Rua X, 123 - Centro, Cidade/UF").
  final String label;
  final String? street;
  final String? number;

  /// Bairro.
  final String? district;
  final String? city;

  /// UF com 2 letras (ex.: "PR").
  final String? state;

  /// Presentes no autocomplete; o reverse não devolve coordenadas (o ponto
  /// consultado já é a coordenada).
  final double? latitude;
  final double? longitude;

  static String? _nonEmpty(Object? value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }

  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    return AddressSuggestion(
      label: (json['label'] ?? '').toString(),
      street: _nonEmpty(json['street']),
      number: _nonEmpty(json['number']),
      district: _nonEmpty(json['district']),
      city: _nonEmpty(json['city']),
      state: _nonEmpty(json['state']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
