import '../models/child.dart';

abstract interface class ChildrenRepository {
  Future<List<Child>> getChildren();

  Future<Child?> getChildById(int id);

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
  });

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
  });

  Future<void> deleteChild(int id);
}
