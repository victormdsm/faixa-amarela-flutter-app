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

  Future<void> updateChildAddress({
    required int childId,
    required int addressId,
    required ChildAddress address,
  });

  Future<void> createChildAddress({
    required int childId,
    required ChildAddress address,
  });

  Future<Child> uploadChildPhoto({
    required int childId,
    required String filePath,
  });
}
