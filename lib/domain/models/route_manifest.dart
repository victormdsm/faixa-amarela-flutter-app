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
    this.id,
    required this.childId,
    required this.childName,
    required this.schoolName,
    this.schoolId,
    required this.address,
    required this.sequence,
    required this.status,
    this.type,
    this.latitude,
    this.longitude,
    this.boardedAt,
    this.disembarkedAt,
  });

  /// APP-24: o backend não emite id de parada no manifesto — opcional,
  /// default null (antes era required e todo stop chegava com id=0).
  final int? id;
  final int childId;
  final String childName;
  final String schoolName;
  final int? schoolId;
  final String address;
  final int sequence;
  final StopStatus status;

  /// Tipo do stop no manifesto ("pickup", "school"). Stops "school" são a
  /// âncora da viagem (embarque na escola na volta / chegada na ida) — não
  /// têm criança nem ações de embarque.
  final String? type;
  final double? latitude;
  final double? longitude;
  final DateTime? boardedAt;
  final DateTime? disembarkedAt;

  /// Stop de escola (âncora da viagem): não é acionável (sem embarque/
  /// desembarque/remoção) — aparece apenas como ponto no mapa.
  bool get isSchoolAnchor => (type ?? '').toLowerCase() == 'school';
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
}
