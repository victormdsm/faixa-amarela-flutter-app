enum EnrollmentStatus {
  pending,
  active,
  rejected,
  canceled;

  factory EnrollmentStatus.fromJson(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return EnrollmentStatus.active;
      case 'rejected':
        return EnrollmentStatus.rejected;
      case 'canceled':
        return EnrollmentStatus.canceled;
      case 'pending':
      default:
        return EnrollmentStatus.pending;
    }
  }

  String toJson() => name;
}

class Enrollment {
  const Enrollment({
    required this.id,
    required this.childId,
    required this.childName,
    required this.driverId,
    required this.driverName,
    required this.vanPlate,
    required this.schoolName,
    required this.status,
    this.requestedAt,
    this.respondedAt,
  });

  final int id;
  final int childId;
  final String childName;
  final int driverId;
  final String driverName;
  final String vanPlate;
  final String schoolName;
  final EnrollmentStatus status;
  final DateTime? requestedAt;
  final DateTime? respondedAt;

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      childId: (json['childId'] as num?)?.toInt() ?? 0,
      childName: (json['childName'] ?? '').toString(),
      driverId: (json['driverId'] as num?)?.toInt() ?? 0,
      driverName: (json['driverName'] ?? '').toString(),
      vanPlate: (json['vanPlate'] ?? '').toString(),
      schoolName: (json['schoolName'] ?? '').toString(),
      status: EnrollmentStatus.fromJson(
        (json['status'] ?? 'pending').toString(),
      ),
      requestedAt: json['requestedAt'] != null
          ? DateTime.tryParse(json['requestedAt'].toString())
          : null,
      respondedAt: json['respondedAt'] != null
          ? DateTime.tryParse(json['respondedAt'].toString())
          : null,
    );
  }
}
