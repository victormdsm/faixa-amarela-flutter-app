import '../models/child.dart';

abstract interface class ChildrenRepository {
  Future<List<Child>> getChildren();

  Future<Child?> getChildById(int id);

  Future<Child> createChild({
    required String name,
    required String cpf,
    required int? schoolId,
    required int? shiftId,
    required ChildAddress address,
  });

  Future<Child> updateChild({
    required int id,
    String? name,
    String? cpf,
    int? schoolId,
    int? shiftId,
  });

  Future<void> deleteChild(int id);

  Future<List<Map<String, dynamic>>> getChildAddresses(int childId);

  /// Geocoding leve (texto livre) para plotar o endereço no mapa enquanto o
  /// pai digita. Retorna null quando o endereço não é localizado — nesse caso
  /// o mapa não aparece e o cadastro segue sem coordenadas, como hoje.
  Future<({double latitude, double longitude, String? label})?> geocodeAddress(
    String text,
  );

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
