import '../models/enrollment.dart';

abstract interface class EnrollmentsRepository {
  // Parent actions
  Future<List<Enrollment>> getPendingEnrollments();

  Future<void> acceptEnrollment(int id);

  Future<void> rejectEnrollment(int id);

  // Driver actions
  Future<ChildLookupResult> lookupChildByCpf(String cpf);

  Future<void> requestEnrollment(int childId);

  Future<List<Enrollment>> getMyEnrollments();
}

class ChildLookupResult {
  const ChildLookupResult({
    required this.found,
    this.childId,
    this.childName,
    this.schoolName,
    this.shiftName,
    this.parentName,
    this.address,
    this.isInDebt = false,
    this.hasPendingEnrollment = false,
  });

  final bool found;
  final int? childId;
  final String? childName;
  final String? schoolName;
  final String? shiftName;
  final String? parentName;
  final String? address;
  final bool isInDebt;
  final bool hasPendingEnrollment;

  factory ChildLookupResult.fromJson(Map<String, dynamic> json) {
    final child = json['child'] is Map<String, dynamic>
        ? json['child'] as Map<String, dynamic>
        : json;

    return ChildLookupResult(
      found:
          json['found'] == true ||
          json['found'] == 1 ||
          child['id'] != null,
      childId:
          (json['child_id'] as num?)?.toInt() ?? (child['id'] as num?)?.toInt(),
      childName:
          json['child_name']?.toString() ??
          json['childName']?.toString() ??
          child['name']?.toString(),
      schoolName:
          json['school_name']?.toString() ??
          json['schoolName']?.toString() ??
          child['school_name']?.toString() ??
          child['schoolName']?.toString(),
      shiftName:
          child['shift_name']?.toString() ?? child['shiftName']?.toString(),
      parentName:
          child['parent_name']?.toString() ?? child['parentName']?.toString(),
      address: _extractAddress(child['address']),
      isInDebt:
          child['is_in_debt'] == true ||
          child['is_in_debt'] == 1 ||
          child['inadimplencyAlert'] == true ||
          child['inadimplencyAlert'] == 1,
      hasPendingEnrollment:
          json['has_pending_enrollment'] == true ||
          json['has_pending_enrollment'] == 1 ||
          json['hasPendingEnrollment'] == true ||
          json['hasPendingEnrollment'] == 1,
    );
  }

  static String? _extractAddress(dynamic raw) {
    if (raw is! Map<String, dynamic>) return raw?.toString();
    final parts = <String?>[
      raw['street']?.toString(),
      raw['number']?.toString(),
      raw['neighborhood']?.toString(),
      raw['city']?.toString(),
    ].where((s) => s != null && s.isNotEmpty).cast<String>().toList();
    return parts.isEmpty ? null : parts.join(', ');
  }
}
