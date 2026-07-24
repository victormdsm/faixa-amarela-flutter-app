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
    required String cpf,
    required int? schoolId,
    required int? shiftId,
    required ChildAddress address,
  }) async {
    final child = Child(
      id: _children.length + 1,
      name: name,
      cpf: cpf,
      schoolId: schoolId,
      shiftId: shiftId,
    );
    _children.add(child);
    await createChildAddress(childId: child.id, address: address);
    return child;
  }

  @override
  Future<Child> updateChild({
    required int id,
    String? name,
    String? cpf,
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
      cpf: cpf ?? existing.cpf,
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
  }) async {
    _addresses.add({
      'id': _addresses.length + 1,
      'child_id': childId,
      'street': address.street,
      'number': address.number,
      'complement': address.complement,
      'zip_code': address.zipCode,
    });
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
