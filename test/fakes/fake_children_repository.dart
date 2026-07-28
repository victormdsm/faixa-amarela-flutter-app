import 'package:app_faixa_amarela/domain/models/address_suggestion.dart';
import 'package:app_faixa_amarela/domain/models/child.dart';
import 'package:app_faixa_amarela/domain/repositories/children_repository.dart';

class FakeChildrenRepository implements ChildrenRepository {
  final List<Child> _children = [];
  final List<Map<String, dynamic>> _addresses = [];

  void addChild(Child child) => _children.add(child);

  @override
  Future<List<Child>> getChildren() async => List.unmodifiable(_children);

  @override
  Future<Child?> getChildById(int id) async {
    try {
      return _children.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Child> createChild({
    required String name,
    required String document,
    String documentType = ChildDocumentType.cpf,
    String? documentState,
    required int? schoolId,
    required int? shiftId,
    required ChildAddress address,
  }) async {
    final child = Child(
      id: _children.length + 1,
      name: name,
      cpf: document,
      documentType: documentType,
      documentState: documentState,
      schoolId: schoolId,
      shiftId: shiftId,
    );
    _children.add(child);
    await createChildAddress(childId: child.id, address: address, isDefault: true);
    return child;
  }

  @override
  Future<Child> updateChild({
    required int id,
    String? name,
    String? document,
    String? documentType,
    String? documentState,
    int? schoolId,
    int? shiftId,
  }) async {
    final index = _children.indexWhere((c) => c.id == id);
    if (index == -1) {
      throw Exception('Child not found');
    }
    final existing = _children[index];
    _children[index] = Child(
      id: existing.id,
      name: name ?? existing.name,
      cpf: document ?? existing.cpf,
      documentType: documentType ?? existing.documentType,
      documentState: documentState ?? existing.documentState,
      schoolId: schoolId ?? existing.schoolId,
      shiftId: shiftId ?? existing.shiftId,
      isInDebt: existing.isInDebt,
      createdAt: existing.createdAt,
    );
    return _children[index];
  }

  @override
  Future<void> deleteChild(int id) async {
    _children.removeWhere((c) => c.id == id);
    _addresses.removeWhere((a) => a['child_id'] == id);
  }

  @override
  Future<List<Map<String, dynamic>>> getChildAddresses(int childId) async {
    return _addresses
        .where((a) => a['child_id'] == childId)
        .toList(growable: false);
  }

  @override
  Future<({double latitude, double longitude, String? label})?>
  geocodeAddress(String text) async {
    // Fake: sem geocoder — o mapa simplesmente não aparece nos testes.
    return null;
  }

  @override
  Future<List<AddressSuggestion>> autocompleteAddress(
    String text, {
    String? city,
  }) async {
    // Fake: sem autocomplete nos testes.
    return const [];
  }

  @override
  Future<AddressSuggestion> reverseAddress({
    required double latitude,
    required double longitude,
  }) async {
    // Fake: reverse sempre resolve um endereço fixo.
    return const AddressSuggestion(label: 'Endereço de teste');
  }

  @override
  Future<void> updateChildAddress({
    required int childId,
    required int addressId,
    required ChildAddress address,
  }) async {
    final index = _addresses.indexWhere(
      (a) => a['child_id'] == childId && a['id'] == addressId,
    );
    if (index == -1) {
      throw Exception('Address not found');
    }
    _addresses[index] = {
      'id': addressId,
      'child_id': childId,
      'street': address.street,
      'number': address.number,
      'complement': address.complement,
      'zip_code': address.zipCode,
    };
  }

  @override
  Future<void> createChildAddress({
    required int childId,
    required ChildAddress address,
    bool isDefault = false,
  }) async {
    if (isDefault) {
      for (var i = 0; i < _addresses.length; i++) {
        if (_addresses[i]['child_id'] == childId) {
          _addresses[i] = {..._addresses[i], 'is_default': false};
        }
      }
    }
    _addresses.add({
      'id': _addresses.length + 1,
      'child_id': childId,
      'street': address.street,
      'number': address.number,
      'complement': address.complement,
      'zip_code': address.zipCode,
      'is_default': isDefault,
    });
  }

  @override
  Future<void> deleteChildAddress({
    required int childId,
    required int addressId,
  }) async {
    _addresses.removeWhere(
      (a) => a['child_id'] == childId && a['id'] == addressId,
    );
  }

  @override
  Future<void> setChildAddressDefault({
    required int childId,
    required int addressId,
  }) async {
    var found = false;
    for (var i = 0; i < _addresses.length; i++) {
      if (_addresses[i]['child_id'] != childId) continue;
      final isTarget = _addresses[i]['id'] == addressId;
      if (isTarget) found = true;
      _addresses[i] = {..._addresses[i], 'is_default': isTarget};
    }
    if (!found) {
      throw Exception('Address not found');
    }
  }

  @override
  Future<Child> uploadChildPhoto({
    required int childId,
    required String filePath,
  }) async {
    final index = _children.indexWhere((c) => c.id == childId);
    if (index == -1) {
      throw Exception('Child not found');
    }
    final existing = _children[index];
    _children[index] = Child(
      id: existing.id,
      name: existing.name,
      cpf: existing.cpf,
      schoolId: existing.schoolId,
      shiftId: existing.shiftId,
      isInDebt: existing.isInDebt,
      createdAt: existing.createdAt,
      photoUrl: 'file://$filePath',
    );
    return _children[index];
  }
}
