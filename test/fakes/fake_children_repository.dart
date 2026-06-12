import 'package:app_faixa_amarela/domain/models/child.dart';
import 'package:app_faixa_amarela/domain/repositories/children_repository.dart';

class FakeChildrenRepository implements ChildrenRepository {
  final List<Child> _children = [];

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
    required DateTime birthDate,
    required String schoolName,
    required int shiftId,
    required String shiftName,
    required int parentId,
    required String parentName,
    required ChildAddress address,
    String? photoUrl,
  }) async {
    final child = Child(
      id: _children.length + 1,
      name: name,
      cpf: cpf,
      birthDate: birthDate,
      schoolName: schoolName,
      shiftId: shiftId,
      shiftName: shiftName,
      parentId: parentId,
      parentName: parentName,
      address: address,
      photoUrl: photoUrl,
    );
    _children.add(child);
    return child;
  }

  @override
  Future<Child> updateChild({
    required int id,
    String? name,
    String? cpf,
    DateTime? birthDate,
    String? schoolName,
    int? shiftId,
    String? shiftName,
    int? parentId,
    String? parentName,
    ChildAddress? address,
    String? photoUrl,
  }) async {
    final index = _children.indexWhere((c) => c.id == id);
    final existing = _children[index];
    _children[index] = Child(
      id: existing.id,
      name: name ?? existing.name,
      cpf: cpf ?? existing.cpf,
      birthDate: birthDate ?? existing.birthDate,
      schoolName: schoolName ?? existing.schoolName,
      shiftId: shiftId ?? existing.shiftId,
      shiftName: shiftName ?? existing.shiftName,
      parentId: parentId ?? existing.parentId,
      parentName: parentName ?? existing.parentName,
      address: address ?? existing.address,
      photoUrl: photoUrl ?? existing.photoUrl,
    );
    return _children[index];
  }

  @override
  Future<void> deleteChild(int id) async {
    _children.removeWhere((c) => c.id == id);
  }
}
