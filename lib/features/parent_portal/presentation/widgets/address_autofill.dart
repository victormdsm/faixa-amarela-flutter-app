import '../../../../core/models/catalog_option.dart';
import 'address_map_picker.dart';
import 'city_state_fields.dart';

/// Regras de preenchimento automático dos campos de endereço a partir de uma
/// sugestão (autocomplete) ou do reverse geocoding do mapa.
///
/// Contrato por origem ([AddressResolveSource]):
/// - `search`: o usuário escolheu a sugestão explicitamente — preenche tudo
///   o que a sugestão trouxer; o que ela NÃO trouxer (ex.: número ausente
///   numa venue/condomínio) é preservado como o usuário digitou.
/// - `reverse`: efeito colateral de mover o mapa — preenche SOMENTE campos
///   vazios; nunca sobrescreve o que o usuário digitou ou selecionou.

/// Novo valor de um campo de texto (rua, número, bairro...).
String autofillTextValue({
  required String current,
  required String? incoming,
  required AddressResolveSource source,
}) {
  final suggestion = (incoming ?? '').trim();
  if (suggestion.isEmpty) return current;
  if (source == AddressResolveSource.reverse && current.trim().isNotEmpty) {
    return current;
  }
  return suggestion;
}

/// Nova UF selecionada, sempre com match exato na lista de UFs válidas.
/// Reverse só preenche quando nenhuma UF foi escolhida; search pode trocar.
String? autofillStateUf({
  required String? currentUf,
  required String? incomingState,
  required AddressResolveSource source,
}) {
  final uf = incomingState?.trim().toUpperCase();
  if (uf == null || !kBrazilStates.contains(uf)) return currentUf;
  if (source == AddressResolveSource.reverse && currentUf != null) {
    return currentUf;
  }
  return uf;
}

/// Nova cidade selecionada: só com match exato (case-insensitive) no
/// catálogo — autofill nunca chuta uma cidade "parecida". Reverse também
/// exige que nenhuma cidade tenha sido escolhida pelo usuário.
CatalogOption? autofillCity({
  required CatalogOption? currentCity,
  required String? incomingCityName,
  required List<CatalogOption> catalog,
  required AddressResolveSource source,
}) {
  if (source == AddressResolveSource.reverse && currentCity != null) {
    return currentCity;
  }
  final query = (incomingCityName ?? '').trim().toLowerCase();
  if (query.isEmpty) return currentCity;
  for (final city in catalog) {
    if (city.name.trim().toLowerCase() == query) return city;
  }
  return currentCity;
}
