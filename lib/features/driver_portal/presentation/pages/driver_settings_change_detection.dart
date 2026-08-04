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

/// Detecta edição na lista de escolas atendidas comparada à carregada do
/// servidor.
bool hasSchoolChanges({
  required Set<int> selectedSchoolIds,
  required Set<int> originalSelectedSchoolIds,
}) {
  return !const SetEquality<int>().equals(
    selectedSchoolIds,
    originalSelectedSchoolIds,
  );
}

/// Detecta edição na lista de bairros atendidos comparada à carregada do
/// servidor.
///
/// Extraído para ser testável isoladamente — é o que decide se
/// `requestedDistrictIds`/`requestedSchoolShiftMap` entram no submit da
/// solicitação: trocar só a foto/avatar NÃO pode reenviar a cobertura.
/// (Antes comparava o mapa bairro→turnos, que morreu: turnos agora são
/// herdados da escola, read-only.)
bool hasDistrictChanges({
  required Set<int> selectedDistrictIds,
  required Set<int> originalSelectedDistrictIds,
}) {
  return !const SetEquality<int>().equals(
    selectedDistrictIds,
    originalSelectedDistrictIds,
  );
}

/// Detecta alterações que exigem solicitação de aprovação do admin:
/// escolas, bairros, fotos (perfil/veículo) e dados da van.
bool hasCoverageChanges({
  required Set<int> selectedSchoolIds,
  required Set<int> originalSelectedSchoolIds,
  required Set<int> selectedDistrictIds,
  required Set<int> originalSelectedDistrictIds,
  required bool hasNewAvatarImage,
  required bool hasNewVehicleImage,
  required bool hasVehicleDataChanges,
}) {
  if (hasSchoolChanges(
    selectedSchoolIds: selectedSchoolIds,
    originalSelectedSchoolIds: originalSelectedSchoolIds,
  )) {
    return true;
  }
  if (hasDistrictChanges(
    selectedDistrictIds: selectedDistrictIds,
    originalSelectedDistrictIds: originalSelectedDistrictIds,
  )) {
    return true;
  }
  if (hasNewAvatarImage) return true;
  if (hasNewVehicleImage) return true;
  // Edição dos dados da van também passa pela solicitação de aprovação —
  // sem isso o _save nem entraria no fluxo de request para a van.
  if (hasVehicleDataChanges) return true;
  return false;
}
