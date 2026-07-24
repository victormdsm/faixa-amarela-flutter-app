class ParentBoardingRecord {
  const ParentBoardingRecord({
    required this.status,
    this.boarding,
    this.client,
    this.createdAt,
  });

  final String status;
  final BoardingInfo? boarding;
  final BoardingClientInfo? client;
  final String? createdAt;

  factory ParentBoardingRecord.fromJson(Map<String, dynamic> json) {
    final boardingRaw = json['boarding'];
    final clientRaw = json['client'];

    return ParentBoardingRecord(
      status: (json['status'] ?? 'N/A').toString(),
      boarding: boardingRaw is Map
          ? BoardingInfo.fromJson(Map<String, dynamic>.from(boardingRaw))
          : null,
      client: clientRaw is Map
          ? BoardingClientInfo.fromJson(Map<String, dynamic>.from(clientRaw))
          : null,
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      if (boarding != null) 'boarding': boarding!.toJson(),
      if (client != null) 'client': client!.toJson(),
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}

class BoardingInfo {
  const BoardingInfo({
    this.route,
    this.hourBoarding,
    this.hourDisembarking,
  });

  final BoardingRouteInfo? route;
  final String? hourBoarding;
  final String? hourDisembarking;

  factory BoardingInfo.fromJson(Map<String, dynamic> json) {
    final routeRaw = json['route'];
    return BoardingInfo(
      route: routeRaw is Map
          ? BoardingRouteInfo.fromJson(Map<String, dynamic>.from(routeRaw))
          : null,
      hourBoarding: json['hourBoarding']?.toString(),
      hourDisembarking: json['hourDisembarking']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (route != null) 'route': route!.toJson(),
      if (hourBoarding != null) 'hourBoarding': hourBoarding,
      if (hourDisembarking != null) 'hourDisembarking': hourDisembarking,
    };
  }
}

class BoardingRouteInfo {
  const BoardingRouteInfo({this.name});

  final String? name;

  factory BoardingRouteInfo.fromJson(Map<String, dynamic> json) {
    return BoardingRouteInfo(name: json['name']?.toString());
  }

  Map<String, dynamic> toJson() {
    return {if (name != null) 'name': name};
  }
}

class BoardingClientInfo {
  const BoardingClientInfo({this.child});

  final BoardingChildInfo? child;

  factory BoardingClientInfo.fromJson(Map<String, dynamic> json) {
    final childRaw = json['child'];
    return BoardingClientInfo(
      child: childRaw is Map
          ? BoardingChildInfo.fromJson(Map<String, dynamic>.from(childRaw))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {if (child != null) 'child': child!.toJson()};
  }
}

class BoardingChildInfo {
  const BoardingChildInfo({this.name});

  final String? name;

  factory BoardingChildInfo.fromJson(Map<String, dynamic> json) {
    return BoardingChildInfo(name: json['name']?.toString());
  }

  Map<String, dynamic> toJson() {
    return {if (name != null) 'name': name};
  }
}
