import '../../core/error/app_failure.dart';
import '../models/address_suggestion.dart';
import '../models/child.dart';

abstract interface class ChildrenRepository {
  Future<List<Child>> getChildren();

  Future<Child?> getChildById(int id);

  /// Cria a criança. [document] é o número do CPF ou RG (conforme
  /// [documentType]); [documentState] (UF) só é enviado quando RG — o
  /// backend o rejeita para CPF.
  Future<Child> createChild({
    required String name,
    required String document,
    String documentType = ChildDocumentType.cpf,
    String? documentState,
    required int? schoolId,
    required int? shiftId,
    required ChildAddress address,
  });

  Future<Child> updateChild({
    required int id,
    String? name,
    String? document,
    String? documentType,
    String? documentState,
    int? schoolId,
    int? shiftId,
  });

  Future<void> deleteChild(int id);

  Future<List<Map<String, dynamic>>> getChildAddresses(int childId);

  /// Geocoding leve (texto livre). Lança [AppFailure] amigável quando o
  /// endereço não é localizado (404) ou o serviço falha — o chamador decide
  /// como exibir; nunca é engolido silenciosamente.
  Future<({double latitude, double longitude, String? label})?> geocodeAddress(
    String text,
  );

  /// Autocomplete de endereços (até 5 sugestões), com viés opcional de
  /// [city]. Lança [AppFailure] amigável em caso de erro.
  Future<List<AddressSuggestion>> autocompleteAddress(
    String text, {
    String? city,
  });

  /// Reverse geocoding do ponto (lat/lon) — usado quando o pai move o mapa.
  /// Lança [NotFoundFailure] com mensagem amigável quando o ponto não
  /// resolve um endereço.
  Future<AddressSuggestion> reverseAddress({
    required double latitude,
    required double longitude,
  });

  Future<void> updateChildAddress({
    required int childId,
    required int addressId,
    required ChildAddress address,
  });

  Future<void> createChildAddress({
    required int childId,
    required ChildAddress address,
    bool isDefault = false,
  });

  Future<void> deleteChildAddress({
    required int childId,
    required int addressId,
  });

  /// Marca o endereço como default da criança (o backend desmarca os demais).
  Future<void> setChildAddressDefault({
    required int childId,
    required int addressId,
  });

  Future<Child> uploadChildPhoto({
    required int childId,
    required String filePath,
  });
}
