class DriverProfileChangeRequest {
  const DriverProfileChangeRequest({
    required this.id,
    required this.driverUserId,
    required this.requestedByUserId,
    required this.status,
    this.requestedSchoolIds,
    this.requestedDistrictIds,
    this.requestedSchoolShiftMap,
    this.currentSchoolIds,
    this.currentDistrictIds,
    this.currentSchoolShiftMap,
    this.requestedDistrictShiftMap,
    this.currentDistrictShiftMap,
    this.requestedAvatarPath,
    this.currentAvatarPath,
    this.requestedVehicleImagePath,
    this.currentVehicleImagePath,
    this.vehicleId,
    this.requestNote,
    this.reviewNote,
    this.reviewedByAdminId,
    this.reviewedAt,
    this.createdAt,
  });

  final int id;
  final int driverUserId;
  final int requestedByUserId;
  final String status;
  final List<int>? requestedSchoolIds;
  final List<int>? requestedDistrictIds;

  /// Mapa escola→turnos desejado (contrato novo — turnos herdados das
  /// escolas). Substitui [requestedDistrictShiftMap].
  final Map<String, List<int>>? requestedSchoolShiftMap;
  final List<int>? currentSchoolIds;
  final List<int>? currentDistrictIds;
  final Map<String, List<int>>? currentSchoolShiftMap;

  /// Legado (solicitações antigas): mapa bairro→turnos.
  final Map<String, List<int>>? requestedDistrictShiftMap;
  final Map<String, List<int>>? currentDistrictShiftMap;
  final String? requestedAvatarPath;
  final String? currentAvatarPath;
  final String? requestedVehicleImagePath;
  final String? currentVehicleImagePath;
  final int? vehicleId;
  final String? requestNote;
  final String? reviewNote;
  final int? reviewedByAdminId;
  final DateTime? reviewedAt;
  final DateTime? createdAt;

  factory DriverProfileChangeRequest.fromJson(Map<String, dynamic> json) {
    List<int>? toIntList(dynamic raw) {
      if (raw is! List) return null;
      return raw
          .whereType<num>()
          .map((e) => e.toInt())
          .toList(growable: false);
    }

    Map<String, List<int>>? toShiftMap(dynamic raw) {
      if (raw is! Map) return null;
      final result = <String, List<int>>{};
      for (final entry in raw.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is List) {
          result[key] = value.whereType<num>().map((e) => e.toInt()).toList();
        }
      }
      return result;
    }

    return DriverProfileChangeRequest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      driverUserId: (json['driverUserId'] as num?)?.toInt() ?? 0,
      requestedByUserId: (json['requestedByUserId'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? '').toString(),
      requestedSchoolIds: toIntList(json['requestedSchoolIds']),
      requestedDistrictIds: toIntList(json['requestedDistrictIds']),
      requestedSchoolShiftMap: toShiftMap(json['requestedSchoolShiftMap']),
      currentSchoolIds: toIntList(json['currentSchoolIds']),
      currentDistrictIds: toIntList(json['currentDistrictIds']),
      currentSchoolShiftMap: toShiftMap(json['currentSchoolShiftMap']),
      requestedDistrictShiftMap: toShiftMap(json['requestedDistrictShiftMap']),
      currentDistrictShiftMap: toShiftMap(json['currentDistrictShiftMap']),
      requestedAvatarPath: json['requestedAvatarPath']?.toString(),
      currentAvatarPath: json['currentAvatarPath']?.toString(),
      requestedVehicleImagePath: json['requestedVehicleImagePath']?.toString(),
      currentVehicleImagePath: json['currentVehicleImagePath']?.toString(),
      vehicleId: (json['vehicleId'] as num?)?.toInt(),
      requestNote: json['requestNote']?.toString(),
      reviewNote: json['reviewNote']?.toString(),
      reviewedByAdminId: (json['reviewedByAdminId'] as num?)?.toInt(),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
