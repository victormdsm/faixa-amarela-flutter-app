import '../../domain/models/route_manifest.dart';

class RouteManifestDto {
  const RouteManifestDto({
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

  /// ID numérico da rota (route.id).
  final int id;

  /// ID UUID do manifesto (manifest.id).
  final String? manifestId;

  final int driverId;
  final int vanId;
  final int? shiftId;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final RouteStatus status;
  final List<RouteStopDto> stops;

  factory RouteManifestDto.fromJson(
    Map<String, dynamic> json, {
    Map<int, Map<String, dynamic>>? childLookup,
  }) {
    // O NestJS retorna route.id como int e manifest.id como UUID.
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

    final rawStops = json['stops'];
    final stops = rawStops is List
        ? rawStops
            .whereType<Map>()
            .map(
              (e) => RouteStopDto.fromJson(
                Map<String, dynamic>.from(e),
                childLookup: childLookup,
              ),
            )
            .toList()
        : const <RouteStopDto>[];

    return RouteManifestDto(
      id: resolveId(),
      manifestId: resolveManifestId(),
      driverId: (_value(json, 'driver_id', 'driverId') as num?)?.toInt() ?? 0,
      vanId: (_value(json, 'van_id', 'vanId') as num?)?.toInt() ?? 0,
      shiftId: resolveShiftId(),
      startedAt: _value(json, 'started_at', 'startedAt') != null
          ? DateTime.tryParse(
              _value(json, 'started_at', 'startedAt').toString(),
            )
          : null,
      finishedAt: _value(json, 'finished_at', 'finishedAt') != null
          ? DateTime.tryParse(
              _value(json, 'finished_at', 'finishedAt').toString(),
            )
          : null,
      status: RouteStatus.fromJson((json['status'] ?? 'planning').toString()),
      stops: stops,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (manifestId != null) 'manifest_id': manifestId,
      'driver_id': driverId,
      'van_id': vanId,
      if (shiftId != null) 'shift_id': shiftId,
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (finishedAt != null) 'finished_at': finishedAt!.toIso8601String(),
      'status': status.toJson(),
      'stops': stops.map((s) => s.toJson()).toList(),
    };
  }

  RouteManifest toDomain() {
    return RouteManifest(
      id: id,
      manifestId: manifestId,
      driverId: driverId,
      vanId: vanId,
      shiftId: shiftId,
      startedAt: startedAt,
      finishedAt: finishedAt,
      status: status,
      stops: stops.map((s) => s.toDomain()).toList(),
    );
  }

  factory RouteManifestDto.fromDomain(RouteManifest manifest) {
    return RouteManifestDto(
      id: manifest.id,
      manifestId: manifest.manifestId,
      driverId: manifest.driverId,
      vanId: manifest.vanId,
      shiftId: manifest.shiftId,
      startedAt: manifest.startedAt,
      finishedAt: manifest.finishedAt,
      status: manifest.status,
      stops: manifest.stops.map((s) => RouteStopDto.fromDomain(s)).toList(),
    );
  }
}

class RouteStopDto {
  const RouteStopDto({
    required this.id,
    required this.childId,
    required this.childName,
    required this.schoolName,
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
  final String address;
  final int sequence;
  final StopStatus status;
  final double? latitude;
  final double? longitude;
  final DateTime? boardedAt;
  final DateTime? disembarkedAt;

  factory RouteStopDto.fromJson(
    Map<String, dynamic> json, {
    Map<int, Map<String, dynamic>>? childLookup,
  }) {
    final childId = (_value(json, 'child_id', 'childId') as num?)?.toInt() ?? 0;
    final childData = childLookup?[childId] ?? const <String, dynamic>{};

    String resolveAddress() {
      // 1. Formato antigo: address como string.
      final rawAddress = json['address'];
      if (rawAddress is String && rawAddress.isNotEmpty) return rawAddress;

      // 2. Formato NestJS: document.children[].address { street, number }
      final addr = childData['address'];
      if (addr is Map) {
        final street = addr['street']?.toString() ?? '';
        final number = addr['number']?.toString() ?? '';
        if (street.isNotEmpty && number.isNotEmpty) return '$street, $number';
        if (street.isNotEmpty) return street;
      }
      return '';
    }

    return RouteStopDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      childId: childId,
      childName:
          (_value(json, 'child_name', 'childName') ?? childData['name'] ?? '')
              .toString(),
      schoolName: (_value(json, 'school_name', 'schoolName') ?? '').toString(),
      address: resolveAddress(),
      sequence: (json['sequence'] as num?)?.toInt() ??
          (json['order'] as num?)?.toInt() ??
          0,
      status: StopStatus.fromJson((json['status'] ?? 'pending').toString()),
      latitude: (json['latitude'] as num?)?.toDouble() ??
          (childData['address'] is Map
              ? ((childData['address'] as Map)['latitude'] as num?)?.toDouble()
              : null),
      longitude: (json['longitude'] as num?)?.toDouble() ??
          (childData['address'] is Map
              ? ((childData['address'] as Map)['longitude'] as num?)?.toDouble()
              : null),
      boardedAt: _value(json, 'boarded_at', 'boardedAt') != null
          ? DateTime.tryParse(
              _value(json, 'boarded_at', 'boardedAt').toString(),
            )
          : null,
      disembarkedAt: _value(json, 'disembarked_at', 'disembarkedAt') != null
          ? DateTime.tryParse(
              _value(json, 'disembarked_at', 'disembarkedAt').toString(),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'child_id': childId,
      'child_name': childName,
      'school_name': schoolName,
      'address': address,
      'sequence': sequence,
      'status': status.toJson(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (boardedAt != null) 'boarded_at': boardedAt!.toIso8601String(),
      if (disembarkedAt != null)
        'disembarked_at': disembarkedAt!.toIso8601String(),
    };
  }

  RouteStop toDomain() {
    return RouteStop(
      id: id,
      childId: childId,
      childName: childName,
      schoolName: schoolName,
      address: address,
      sequence: sequence,
      status: status,
      latitude: latitude,
      longitude: longitude,
      boardedAt: boardedAt,
      disembarkedAt: disembarkedAt,
    );
  }

  factory RouteStopDto.fromDomain(RouteStop stop) {
    return RouteStopDto(
      id: stop.id,
      childId: stop.childId,
      childName: stop.childName,
      schoolName: stop.schoolName,
      address: stop.address,
      sequence: stop.sequence,
      status: stop.status,
      latitude: stop.latitude,
      longitude: stop.longitude,
      boardedAt: stop.boardedAt,
      disembarkedAt: stop.disembarkedAt,
    );
  }
}

Object? _value(Map<String, dynamic> json, String snakeCase, String camelCase) {
  if (json.containsKey(snakeCase)) return json[snakeCase];
  return json[camelCase];
}
