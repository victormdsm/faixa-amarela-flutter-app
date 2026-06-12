import 'package:app_faixa_amarela/domain/models/enrollment.dart';
import 'package:app_faixa_amarela/domain/repositories/enrollments_repository.dart';

class FakeEnrollmentsRepository implements EnrollmentsRepository {
  final List<Enrollment> _enrollments = [];
  ChildLookupResult? _lookupResult;

  void setLookupResult(ChildLookupResult? result) => _lookupResult = result;
  void addEnrollment(Enrollment enrollment) => _enrollments.add(enrollment);

  @override
  Future<List<Enrollment>> getPendingEnrollments() async {
    return _enrollments
        .where((e) => e.status == EnrollmentStatus.pending)
        .toList();
  }

  @override
  Future<void> acceptEnrollment(int id) async {
    final index = _enrollments.indexWhere((e) => e.id == id);
    if (index != -1) {
      _enrollments[index] = Enrollment(
        id: _enrollments[index].id,
        childId: _enrollments[index].childId,
        childName: _enrollments[index].childName,
        driverId: _enrollments[index].driverId,
        driverName: _enrollments[index].driverName,
        vanPlate: _enrollments[index].vanPlate,
        schoolName: _enrollments[index].schoolName,
        status: EnrollmentStatus.active,
        requestedAt: _enrollments[index].requestedAt,
        respondedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> rejectEnrollment(int id) async {
    final index = _enrollments.indexWhere((e) => e.id == id);
    if (index != -1) {
      _enrollments[index] = Enrollment(
        id: _enrollments[index].id,
        childId: _enrollments[index].childId,
        childName: _enrollments[index].childName,
        driverId: _enrollments[index].driverId,
        driverName: _enrollments[index].driverName,
        vanPlate: _enrollments[index].vanPlate,
        schoolName: _enrollments[index].schoolName,
        status: EnrollmentStatus.rejected,
        requestedAt: _enrollments[index].requestedAt,
        respondedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<ChildLookupResult> lookupChildByCpf(String cpf) async {
    return _lookupResult ?? const ChildLookupResult(found: false);
  }

  @override
  Future<void> requestEnrollment(int childId) async {
    _enrollments.add(
      Enrollment(
        id: _enrollments.length + 1,
        childId: childId,
        childName: 'Criança $childId',
        driverId: 1,
        driverName: 'Motorista',
        vanPlate: 'ABC1234',
        schoolName: 'Escola',
        status: EnrollmentStatus.pending,
        requestedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<Enrollment>> getMyEnrollments() async =>
      List.unmodifiable(_enrollments);
}
