import '../../domain/models/enrollment.dart';

class EnrollmentDto {
  const EnrollmentDto({
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

  factory EnrollmentDto.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final respondedAtRaw = json['respondedAt'] ?? json['acceptedAt'];

    return EnrollmentDto(
      id: toInt(json['id']),
      childId: toInt(json['childId']),
      childName: (json['childName'] ?? '').toString(),
      driverId: toInt(json['driverUserId'] ?? json['driverId']),
      driverName: (json['driverName'] ?? '').toString(),
      vanPlate: (json['vanPlate'] ?? '').toString(),
      schoolName: (json['schoolName'] ?? '').toString(),
      status: EnrollmentStatus.fromJson(
        (json['status'] ?? 'pending').toString(),
      ),
      requestedAt: json['requestedAt'] != null
          ? DateTime.tryParse(json['requestedAt'].toString())
          : null,
      respondedAt: respondedAtRaw != null
          ? DateTime.tryParse(respondedAtRaw.toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'childName': childName,
      'driverId': driverId,
      'driverName': driverName,
      'vanPlate': vanPlate,
      'schoolName': schoolName,
      'status': status.toJson(),
      if (requestedAt != null) 'requestedAt': requestedAt!.toIso8601String(),
      if (respondedAt != null) 'respondedAt': respondedAt!.toIso8601String(),
    };
  }

  Enrollment toDomain() {
    return Enrollment(
      id: id,
      childId: childId,
      childName: childName,
      driverId: driverId,
      driverName: driverName,
      vanPlate: vanPlate,
      schoolName: schoolName,
      status: status,
      requestedAt: requestedAt,
      respondedAt: respondedAt,
    );
  }

  factory EnrollmentDto.fromDomain(Enrollment enrollment) {
    return EnrollmentDto(
      id: enrollment.id,
      childId: enrollment.childId,
      childName: enrollment.childName,
      driverId: enrollment.driverId,
      driverName: enrollment.driverName,
      vanPlate: enrollment.vanPlate,
      schoolName: enrollment.schoolName,
      status: enrollment.status,
      requestedAt: enrollment.requestedAt,
      respondedAt: enrollment.respondedAt,
    );
  }
}

