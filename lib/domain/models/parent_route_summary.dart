class ParentRouteSummary {
  const ParentRouteSummary({
    required this.id,
    this.driverId,
    this.vanId,
    this.shiftId,
    this.status,
    this.startedAt,
    this.finishedAt,
    this.createdAt,
    this.driver,
    this.van,
    this.activeManifest,
    this.latestLocation,
  });

  final int id;
  final int? driverId;
  final int? vanId;
  final int? shiftId;
  final String? status;
  final String? startedAt;
  final String? finishedAt;
  final String? createdAt;
  final RouteDriverSummary? driver;
  final RouteVanSummary? van;
  final Map<String, dynamic>? activeManifest;
  final RouteLatestLocation? latestLocation;

  factory ParentRouteSummary.fromJson(Map<String, dynamic> json) {
    final driverRaw = json['driver'];
    final vanRaw = json['van'];
    final manifestRaw = json['activeManifest'];
    final locationRaw = json['latestLocation'];
    final locationAtRaw = json['latestLocationAt'];

    return ParentRouteSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      driverId: (json['driverId'] as num?)?.toInt(),
      vanId: (json['vanId'] as num?)?.toInt(),
      shiftId: (json['shiftId'] as num?)?.toInt(),
      status: json['status']?.toString(),
      startedAt: json['startedAt']?.toString(),
      finishedAt: json['finishedAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
      driver: driverRaw is Map
          ? RouteDriverSummary.fromJson(Map<String, dynamic>.from(driverRaw))
          : null,
      van: vanRaw is Map
          ? RouteVanSummary.fromJson(Map<String, dynamic>.from(vanRaw))
          : null,
      activeManifest: manifestRaw is Map
          ? Map<String, dynamic>.from(manifestRaw)
          : null,
      latestLocation: locationRaw is Map
          ? RouteLatestLocation.fromJson(
              Map<String, dynamic>.from(locationRaw),
              timestamp: locationAtRaw,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (driverId != null) 'driverId': driverId,
      if (vanId != null) 'vanId': vanId,
      if (shiftId != null) 'shiftId': shiftId,
      if (status != null) 'status': status,
      if (startedAt != null) 'startedAt': startedAt,
      if (finishedAt != null) 'finishedAt': finishedAt,
      if (createdAt != null) 'createdAt': createdAt,
      if (driver != null) 'driver': driver!.toJson(),
      if (van != null) 'van': van!.toJson(),
      if (activeManifest != null) 'activeManifest': activeManifest,
      if (latestLocation != null) 'latestLocation': latestLocation!.toJson(),
    };
  }
}

class RouteDriverSummary {
  const RouteDriverSummary({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  final int id;
  final String name;
  final String? avatarUrl;

  factory RouteDriverSummary.fromJson(Map<String, dynamic> json) {
    return RouteDriverSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
}

class RouteVanSummary {
  const RouteVanSummary({
    required this.id,
    this.plate,
    this.model,
    this.color,
    this.year,
  });

  final int id;
  final String? plate;
  final String? model;
  final String? color;
  final String? year;

  factory RouteVanSummary.fromJson(Map<String, dynamic> json) {
    return RouteVanSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      plate: json['plate']?.toString(),
      model: json['model']?.toString(),
      color: json['color']?.toString(),
      year: json['year']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (plate != null) 'plate': plate,
      if (model != null) 'model': model,
      if (color != null) 'color': color,
      if (year != null) 'year': year,
    };
  }
}

class RouteLatestLocation {
  const RouteLatestLocation({
    this.latitude,
    this.longitude,
    this.timestamp,
  });

  final double? latitude;
  final double? longitude;

  /// Momento em que a posição foi registrada pelo motorista.
  ///
  /// Vem do campo `latestLocationAt` (ISO 8601) da resposta de rotas do
  /// responsável; permanece `null` quando o backend não o envia.
  final DateTime? timestamp;

  factory RouteLatestLocation.fromJson(
    Map<String, dynamic> json, {
    Object? timestamp,
  }) {
    return RouteLatestLocation(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      timestamp: timestamp == null
          ? null
          : DateTime.tryParse(timestamp.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }
}
