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
    int toInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    int resolveId() {
      if (json['routeId'] is num) return (json['routeId'] as num).toInt();
      if (json['routeId'] is String) {
        return int.tryParse(json['routeId']) ?? 0;
      }
      if (json['id'] is num) return (json['id'] as num).toInt();
      if (json['id'] is String) return int.tryParse(json['id']) ?? 0;
      return 0;
    }

    String? resolveManifestId() {
      if (json['manifestId'] is String) return json['manifestId'] as String;
      if (json['id'] is String) return json['id'] as String;
      return null;
    }

    int? resolveShiftId() {
      if (json['shiftId'] == null) return null;
      return toInt(json['shiftId']);
    }

    final effectiveChildLookup = childLookup ?? _buildChildLookup(json);

    final rawStops = json['stops'];
    final stops = rawStops is List
        ? rawStops
            .whereType<Map>()
            .map(
              (e) => RouteStopDto.fromJson(
                Map<String, dynamic>.from(e),
                childLookup: effectiveChildLookup,
              ),
            )
            .toList()
        : const <RouteStopDto>[];

    return RouteManifestDto(
      id: resolveId(),
      manifestId: resolveManifestId(),
      driverId: toInt(json['driverId']),
      vanId: toInt(json['vanId']),
      shiftId: resolveShiftId(),
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString())
          : null,
      finishedAt: json['finishedAt'] != null
          ? DateTime.tryParse(json['finishedAt'].toString())
          : null,
      status: RouteStatus.fromJson((json['status'] ?? 'planning').toString()),
      stops: stops,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (manifestId != null) 'manifestId': manifestId,
      'driverId': driverId,
      'vanId': vanId,
      if (shiftId != null) 'shiftId': shiftId,
      if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
      if (finishedAt != null) 'finishedAt': finishedAt!.toIso8601String(),
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

  static Map<int, Map<String, dynamic>> _buildChildLookup(
    Map<String, dynamic> json,
  ) {
    final document = json['document'];
    if (document is! Map) return const {};
    final children = document['children'];
    if (children is! List) return const {};
    return {
      for (final child in children.whereType<Map>())
        if (child['childId'] is num || child['childId'] is String)
          (child['childId'] is num
                  ? (child['childId'] as num).toInt()
                  : int.tryParse(child['childId'].toString()) ?? 0):
              Map<String, dynamic>.from(child),
    };
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

  final int? id;
  final int childId;
  final String childName;
  final String schoolName;
  final int? schoolId;
  final String address;
  final int sequence;
  final StopStatus status;
  final String? type;
  final double? latitude;
  final double? longitude;
  final DateTime? boardedAt;
  final DateTime? disembarkedAt;

  factory RouteStopDto.fromJson(
    Map<String, dynamic> json, {
    Map<int, Map<String, dynamic>>? childLookup,
  }) {
    int toInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double? toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    final childId = toInt(json['childId']);
    final childData = childLookup?[childId] ?? const <String, dynamic>{};

    int? resolveSchoolId() {
      final raw = json['schoolId'] ?? childData['schoolId'];
      if (raw == null) return null;
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw);
      return null;
    }

    String resolveAddress() {
      // 1. Formato legado: address como string.
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
      id: json['id'] == null ? null : toInt(json['id']),
      childId: childId,
      childName:
          (json['childName'] ?? childData['name'] ?? '').toString(),
      schoolName: (json['schoolName'] ??
              childData['schoolName'] ??
              '')
          .toString(),
      schoolId: resolveSchoolId(),
      address: resolveAddress(),
      sequence: json['sequence'] != null
          ? toInt(json['sequence'])
          : toInt(json['order']),
      status: StopStatus.fromJson((json['status'] ?? 'pending').toString()),
      type: json['type']?.toString(),
      latitude: toDouble(json['latitude']) ??
          (childData['address'] is Map
              ? toDouble((childData['address'] as Map)['latitude'])
              : null),
      longitude: toDouble(json['longitude']) ??
          (childData['address'] is Map
              ? toDouble((childData['address'] as Map)['longitude'])
              : null),
      boardedAt: json['boardedAt'] != null
          ? DateTime.tryParse(json['boardedAt'].toString())
          : null,
      disembarkedAt: json['disembarkedAt'] != null
          ? DateTime.tryParse(json['disembarkedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'childId': childId,
      'childName': childName,
      'schoolName': schoolName,
      if (schoolId != null) 'schoolId': schoolId,
      'address': address,
      'sequence': sequence,
      'status': status.toJson(),
      if (type != null) 'type': type,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (boardedAt != null) 'boardedAt': boardedAt!.toIso8601String(),
      if (disembarkedAt != null)
        'disembarkedAt': disembarkedAt!.toIso8601String(),
    };
  }

  RouteStop toDomain() {
    return RouteStop(
      id: id,
      childId: childId,
      childName: childName,
      schoolName: schoolName,
      schoolId: schoolId,
      address: address,
      sequence: sequence,
      status: status,
      type: type,
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
      schoolId: stop.schoolId,
      address: stop.address,
      sequence: stop.sequence,
      status: stop.status,
      type: stop.type,
      latitude: stop.latitude,
      longitude: stop.longitude,
      boardedAt: stop.boardedAt,
      disembarkedAt: stop.disembarkedAt,
    );
  }
}

