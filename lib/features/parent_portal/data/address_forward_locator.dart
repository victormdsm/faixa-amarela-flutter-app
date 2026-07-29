import '../../../core/error/app_failure.dart';
import '../../../domain/repositories/children_repository.dart';

/// Ponto geocodificado pelo ORS (mesmo shape retornado pelo repositório).
typedef GeocodedPoint = ({double latitude, double longitude, String? label});

/// Resultado do geocode forward do endereço digitado.
///
/// [numberMatched] é false quando a busca COM o número não achou nada e o
/// ponto veio do fallback só com a rua — a UI avisa para ajustar o pin.
typedef ForwardLocateResult = ({GeocodedPoint point, bool numberMatched});

/// Geocode forward de "rua, número, cidade/UF" para plotar o endereço no
/// mapa no ponto exato (considerando o número, não o meio da rua).
///
/// O texto vai intacto para o backend (sem truncar/normalizar). Fallback:
/// se a busca COM o número não for encontrada (o backend responde 404),
/// tenta de novo só com a rua. Retorna null quando nem a rua é encontrada.
/// Erros que não são "não encontrado" (rede, servidor...) propagam para o
/// chamador exibir a mensagem amigável.
Future<ForwardLocateResult?> forwardLocateAddress(
  ChildrenRepository repository, {
  required String street,
  required String number,
  required String cityBias,
}) async {
  final streetText = street.trim();
  final numberText = number.trim();
  if (numberText.isNotEmpty) {
    final exact = await _tryGeocode(
      repository,
      '$streetText, $numberText, $cityBias',
    );
    if (exact != null) return (point: exact, numberMatched: true);
  }
  final fallback = await _tryGeocode(repository, '$streetText, $cityBias');
  if (fallback == null) return null;
  return (point: fallback, numberMatched: numberText.isEmpty);
}

Future<GeocodedPoint?> _tryGeocode(
  ChildrenRepository repository,
  String text,
) async {
  try {
    return await repository.geocodeAddress(text);
  } on NotFoundFailure {
    return null;
  }
}
