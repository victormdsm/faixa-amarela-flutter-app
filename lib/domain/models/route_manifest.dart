enum RouteStatus {
  planning,
  active,
  finished;

  factory RouteStatus.fromJson(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return RouteStatus.active;
      case 'finished':
        return RouteStatus.finished;
      case 'planning':
      default:
        return RouteStatus.planning;
    }
  }

  String toJson() => name;
}

enum StopStatus {
  pending,
  boarded,
  disembarked,
  absent,
  removed;

  factory StopStatus.fromJson(String value) {
    switch (value.toLowerCase()) {
      case 'boarded':
        return StopStatus.boarded;
      case 'disembarked':
        return StopStatus.disembarked;
      case 'absent':
        return StopStatus.absent;
      case 'removed':
        return StopStatus.removed;
      case 'pending':
      default:
        return StopStatus.pending;
    }
  }

  String toJson() => name;
}

class RouteStop {
  const RouteStop({
    required this.id,
    required this.childId,
    required this.childName,
    required this.schoolName,
    this.schoolId,
    required this.address,
    required this.sequence,
    required this.status,
    this.latitude,
    this.longitude,
    this.boardedAt,
    this.disembarkedAt,
  });

  final int id;
  final int childId;
  final String childName;
  final String schoolName;
  final int? schoolId;
  final String address;
  final int sequence;
  final StopStatus status;
  final double? latitude;
  final double? longitude;
  final DateTime? boardedAt;
  final DateTime? disembarkedAt;

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      id: (json['id'] as num?)?.toInt() ?? 0,
      childId: ((json['child_id'] ?? json['childId']) as num?)?.toInt() ?? 0,
      childName: (json['child_name'] ?? json['childName'] ?? '').toString(),
      schoolName: (json['school_name'] ?? json['schoolName'] ?? '').toString(),
      schoolId: ((json['school_id'] ?? json['schoolId']) as num?)?.toInt(),
      address: (json['address'] ?? '').toString(),
      sequence: ((json['sequence'] ?? json['order']) as num?)?.toInt() ?? 0,
      status: StopStatus.fromJson((json['status'] ?? 'pending').toString()),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      boardedAt: (json['boarded_at'] ?? json['boardedAt']) != null
          ? DateTime.tryParse(
              (json['boarded_at'] ?? json['boardedAt']).toString(),
            )
          : null,
      disembarkedAt: (json['disembarked_at'] ?? json['disembarkedAt']) != null
          ? DateTime.tryParse(
              (json['disembarked_at'] ?? json['disembarkedAt']).toString(),
            )
          : null,
    );
  }
}

class RouteManifest {
  const RouteManifest({
    required this.id,
    this.manifestId,
    required this.driverId,
    required this.vanId,
    this.shiftId,
    this.startedAt,
    this.finishedAt,
    required this.status,
    required this.stops,
  });

  /// ID numérico da rota (route.id). Usado nas URLs de ação (finish, boarding etc).
  final int id;

  /// ID UUID do manifesto (manifest.id). Usado para rastreamento em tempo real.
  final String? manifestId;

  final int driverId;
  final int vanId;
  final int? shiftId;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final RouteStatus status;
  final List<RouteStop> stops;

  factory RouteManifest.fromJson(Map<String, dynamic> json) {
    // O NestJS retorna route.id como int e manifest.id como UUID.
    // Priorizamos routeId quando disponível.
    int resolveId() {
      if (json['routeId'] is num) return (json['routeId'] as num).toInt();
      if (json['routeId'] is String) return int.tryParse(json['routeId']) ?? 0;
      if (json['id'] is num) return (json['id'] as num).toInt();
      return 0;
    }

    String? resolveManifestId() {
      if (json['manifestId'] is String) return json['manifestId'] as String;
      if (json['id'] is String) return json['id'] as String;
      return null;
    }

    int? resolveShiftId() {
      if (json['shiftId'] == null) return null;
      if (json['shiftId'] is num) return (json['shiftId'] as num).toInt();
      if (json['shiftId'] is String) {
        return int.tryParse(json['shiftId'] as String);
      }
      return null;
    }

    return RouteManifest(
      id: resolveId(),
      manifestId: resolveManifestId(),
      driverId:
          ((json['driver_id'] ?? json['driverId']) as num?)?.toInt() ?? 0,
      vanId: ((json['van_id'] ?? json['vanId']) as num?)?.toInt() ?? 0,
      shiftId: resolveShiftId(),
      startedAt: (json['started_at'] ?? json['startedAt']) != null
          ? DateTime.tryParse(
              (json['started_at'] ?? json['startedAt']).toString(),
            )
          : null,
      finishedAt: (json['finished_at'] ?? json['finishedAt']) != null
          ? DateTime.tryParse(
              (json['finished_at'] ?? json['finishedAt']).toString(),
            )
          : null,
      status: RouteStatus.fromJson((json['status'] ?? 'planning').toString()),
      stops:
          (json['stops'] as List<dynamic>?)
              ?.map(
                (e) => RouteStop.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList() ??
          const [],
    );
  }
}
