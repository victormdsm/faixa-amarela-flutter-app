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
    return EnrollmentDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      childId: (_value(json, 'child_id', 'childId') as num?)?.toInt() ?? 0,
      childName: (_value(json, 'child_name', 'childName') ?? '').toString(),
      driverId:
          ((_value(json, 'driver_id', 'driverId') ??
                      _value(json, 'driver_user_id', 'driverUserId'))
                  as num?)
              ?.toInt() ??
          0,
      driverName: (_value(json, 'driver_name', 'driverName') ?? '').toString(),
      vanPlate: (_value(json, 'van_plate', 'vanPlate') ?? '').toString(),
      schoolName: (_value(json, 'school_name', 'schoolName') ?? '').toString(),
      status: EnrollmentStatus.fromJson(
        (json['status'] ?? 'pending').toString(),
      ),
      requestedAt: _value(json, 'requested_at', 'requestedAt') != null
          ? DateTime.tryParse(
              _value(json, 'requested_at', 'requestedAt').toString(),
            )
          : null,
      respondedAt:
          (_value(json, 'responded_at', 'respondedAt') ??
                  _value(json, 'accepted_at', 'acceptedAt')) !=
              null
          ? DateTime.tryParse(
              (_value(json, 'responded_at', 'respondedAt') ??
                      _value(json, 'accepted_at', 'acceptedAt'))
                  .toString(),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'child_id': childId,
      'child_name': childName,
      'driver_id': driverId,
      'driver_name': driverName,
      'van_plate': vanPlate,
      'school_name': schoolName,
      'status': status.toJson(),
      if (requestedAt != null) 'requested_at': requestedAt!.toIso8601String(),
      if (respondedAt != null) 'responded_at': respondedAt!.toIso8601String(),
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

Object? _value(Map<String, dynamic> json, String snakeCase, String camelCase) {
  if (json.containsKey(snakeCase)) return json[snakeCase];
  return json[camelCase];
}
