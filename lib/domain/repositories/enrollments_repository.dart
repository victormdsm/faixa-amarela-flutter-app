import '../models/enrollment.dart';

abstract interface class EnrollmentsRepository {
  // Parent actions
  Future<List<Enrollment>> getPendingEnrollments();

  Future<List<Enrollment>> getActiveEnrollments();

  Future<void> acceptEnrollment(int id);

  Future<void> rejectEnrollment(int id);

  Future<void> cancelEnrollment(int id);

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
    this.districtName,
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
  final String? districtName;
  final String? parentName;
  final String? address;
  final bool isInDebt;
  final bool hasPendingEnrollment;

  factory ChildLookupResult.fromJson(Map<String, dynamic> json) {
    final child = json['child'] is Map<String, dynamic>
        ? json['child'] as Map<String, dynamic>
        : json;

    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return ChildLookupResult(
      found:
          json['found'] == true ||
          json['found'] == 1 ||
          child['id'] != null,
      childId:
          toInt(json['childId']) ??
          toInt(child['id']),
      childName:
          json['childName']?.toString() ??
          child['name']?.toString(),
      schoolName:
          json['schoolName']?.toString() ??
          child['schoolName']?.toString(),
      shiftName:
          json['shiftName']?.toString() ??
          child['shiftName']?.toString(),
      districtName: json['districtName']?.toString(),
      parentName:
          json['parentName']?.toString() ??
          child['parentName']?.toString(),
      address: _extractAddress(json['address'] ?? child['address']),
      isInDebt:
          json['inadimplencyAlert'] == true ||
          json['inadimplencyAlert'] == 1 ||
          child['inadimplencyAlert'] == true ||
          child['inadimplencyAlert'] == 1 ||
          child['isInDebt'] == true ||
          child['isInDebt'] == 1,
      hasPendingEnrollment:
          json['hasPendingEnrollment'] == true ||
          json['hasPendingEnrollment'] == 1,
    );
  }

  static String? _extractAddress(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return raw.isEmpty ? null : raw;
    if (raw is Map) {
      final parts = <String?>[
        raw['street']?.toString(),
        raw['number']?.toString(),
        raw['neighborhood']?.toString(),
        raw['city']?.toString(),
      ].where((s) => s != null && s.isNotEmpty).cast<String>().toList();
      return parts.isEmpty ? null : parts.join(', ');
    }
    return raw.toString();
  }
}
