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

/// Detecta edição no mapa escola→turnos comparado ao carregado do servidor.
bool hasSchoolShiftMapChanges({
  required Map<int, Set<int>> schoolShiftMap,
  required Map<int, Set<int>> originalSchoolShiftMap,
}) {
  final equality = const DeepCollectionEquality();
  return !equality.equals(schoolShiftMap, originalSchoolShiftMap);
}

/// Detecta edição no mapa bairro→turnos comparado ao carregado do servidor.
bool hasDistrictShiftMapChanges({
  required Map<int, Set<int>> districtShiftMap,
  required Map<int, Set<int>> originalDistrictShiftMap,
}) {
  final equality = const DeepCollectionEquality();
  return !equality.equals(districtShiftMap, originalDistrictShiftMap);
}

/// Detecta edição na lista de bairros atendidos comparada à carregada do
/// servidor.
///
/// Extraído para ser testável isoladamente — é o que decide se
/// `requestedDistrictIds`/`requestedSchoolShiftMap` entram no submit da
/// solicitação: trocar só a foto/avatar NÃO pode reenviar a cobertura.
bool hasDistrictChanges({
  required Set<int> selectedDistrictIds,
  required Set<int> originalSelectedDistrictIds,
}) {
  return !const SetEquality<int>().equals(
    selectedDistrictIds,
    originalSelectedDistrictIds,
  );
}

/// Detecta edição no contato público da van — o campo passa a fluir pela
/// solicitação de aprovação do admin (antes ia direto no PUT
/// /drivers/me/vehicle, sem revisão).
bool hasPublicContactChanges({
  required String name,
  required String phone,
  required String originalName,
  required String originalPhone,
}) {
  return name != originalName || phone != originalPhone;
}

/// Validador do contato público obrigatório: nome e telefone precisam estar
/// preenchidos para salvar o perfil/van (mensagem única, amigável).
const String publicContactRequiredMessage =
    'Preencha o nome e telefone de contato público.';

String? validatePublicContactField(String? value) {
  if ((value ?? '').trim().isEmpty) return publicContactRequiredMessage;
  return null;
}

/// Detecta alterações que exigem solicitação de aprovação do admin:
/// escolas, bairros, turnos por escola, turnos por bairro, fotos
/// (perfil/veículo), dados da van e contato público.
bool hasCoverageChanges({
  required Set<int> selectedSchoolIds,
  required Set<int> originalSelectedSchoolIds,
  required Map<int, Set<int>> schoolShiftMap,
  required Map<int, Set<int>> originalSchoolShiftMap,
  required Set<int> selectedDistrictIds,
  required Set<int> originalSelectedDistrictIds,
  required Map<int, Set<int>> districtShiftMap,
  required Map<int, Set<int>> originalDistrictShiftMap,
  required bool hasNewAvatarImage,
  required bool hasNewVehicleImage,
  required bool hasVehicleDataChanges,
  required bool hasPublicContactChanges,
}) {
  if (hasSchoolChanges(
    selectedSchoolIds: selectedSchoolIds,
    originalSelectedSchoolIds: originalSelectedSchoolIds,
  )) {
    return true;
  }
  if (hasSchoolShiftMapChanges(
    schoolShiftMap: schoolShiftMap,
    originalSchoolShiftMap: originalSchoolShiftMap,
  )) {
    return true;
  }
  if (hasDistrictChanges(
    selectedDistrictIds: selectedDistrictIds,
    originalSelectedDistrictIds: originalSelectedDistrictIds,
  )) {
    return true;
  }
  if (hasDistrictShiftMapChanges(
    districtShiftMap: districtShiftMap,
    originalDistrictShiftMap: originalDistrictShiftMap,
  )) {
    return true;
  }
  if (hasNewAvatarImage) return true;
  if (hasNewVehicleImage) return true;
  // Edição dos dados da van também passa pela solicitação de aprovação —
  // sem isso o _save nem entraria no fluxo de request para a van.
  if (hasVehicleDataChanges) return true;
  // Contato público segue o mesmo fluxo de aprovação.
  if (hasPublicContactChanges) return true;
  return false;
}
