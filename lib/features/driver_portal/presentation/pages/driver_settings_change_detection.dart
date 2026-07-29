import 'package:collection/collection.dart';

/// Detecta edição nos dados do veículo comparando os valores atuais do
/// formulário com os valores carregados do servidor.
///
/// Extraído da página para ser testável isoladamente — a regra define tanto
/// a obrigatoriedade da placa quanto o envio dos campos na solicitação de
/// aprovação (dados da van não são mais persistidos direto no perfil).
bool hasVehicleDataChanges({
  required String brand,
  required String color,
  required String year,
  required String plate,
  required String originalBrand,
  required String originalColor,
  required String originalYear,
  required String originalPlate,
}) {
  return brand != originalBrand ||
      color != originalColor ||
      year != originalYear ||
      plate != originalPlate;
}

/// Detecta alterações que exigem solicitação de aprovação do admin:
/// escolas, mapa bairro→turnos, fotos (perfil/veículo) e dados da van.
bool hasCoverageChanges({
  required Set<int> selectedSchoolIds,
  required Set<int> originalSelectedSchoolIds,
  required Map<int, Set<int>> districtShiftMap,
  required Map<int, Set<int>> originalDistrictShiftMap,
  required bool hasNewAvatarImage,
  required bool hasNewVehicleImage,
  required bool hasVehicleDataChanges,
}) {
  if (!const SetEquality<int>().equals(
    selectedSchoolIds,
    originalSelectedSchoolIds,
  )) {
    return true;
  }
  if (districtShiftMap.length != originalDistrictShiftMap.length) {
    return true;
  }
  for (final entry in districtShiftMap.entries) {
    final original = originalDistrictShiftMap[entry.key];
    if (original == null) return true;
    if (!const SetEquality<int>().equals(entry.value, original)) return true;
  }
  if (hasNewAvatarImage) return true;
  if (hasNewVehicleImage) return true;
  // Edição dos dados da van também passa pela solicitação de aprovação —
  // sem isso o _save nem entraria no fluxo de request para a van.
  if (hasVehicleDataChanges) return true;
  return false;
}
