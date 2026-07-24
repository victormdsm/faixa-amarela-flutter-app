class DriverRouteSummary {
  const DriverRouteSummary({
    required this.id,
    this.driverId,
    this.vanId,
    this.shiftId,
    this.status = 'planning',
    this.startedAt,
    this.finishedAt,
    this.createdAt,
    this.boardingsCount = 0,
    this.manifest,
  });

  final int id;
  final int? driverId;
  final int? vanId;
  final int? shiftId;
  final String status;
  final String? startedAt;
  final String? finishedAt;
  final String? createdAt;
  final int boardingsCount;
  final Map<String, dynamic>? manifest;

  factory DriverRouteSummary.fromJson(Map<String, dynamic> json) {
    final manifestRaw = json['manifest'];
    final manifestMap = manifestRaw is Map
        ? Map<String, dynamic>.from(manifestRaw)
        : null;

    // O backend (RouteResponseDto) nao retorna boardingsCount; calculamos
    // localmente a partir das paradas do manifesto.
    final stops = manifestMap?['stops'];
    final computedBoardingsCount =
        stops is List ? stops.whereType<Map>().length : 0;

    return DriverRouteSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      driverId: (json['driverId'] as num?)?.toInt(),
      vanId: (json['vanId'] as num?)?.toInt(),
      shiftId: (json['shiftId'] as num?)?.toInt(),
      status: (json['status'] ?? 'planning').toString(),
      startedAt: json['startedAt']?.toString(),
      finishedAt: json['finishedAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
      boardingsCount: computedBoardingsCount,
      manifest: manifestMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (driverId != null) 'driverId': driverId,
      if (vanId != null) 'vanId': vanId,
      if (shiftId != null) 'shiftId': shiftId,
      'status': status,
      if (startedAt != null) 'startedAt': startedAt,
      if (finishedAt != null) 'finishedAt': finishedAt,
      if (createdAt != null) 'createdAt': createdAt,
      'boardingsCount': boardingsCount,
      if (manifest != null) 'manifest': manifest,
    };
  }
}
