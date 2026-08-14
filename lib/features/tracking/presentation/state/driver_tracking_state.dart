typedef DriverTrackingLatLng = ({double lat, double lng});
typedef DriverTrackingStopPoint = ({
  String? id,
  int? clientId,
  int? childId,
  String? type,
  String status,
  int? sequence,
  double lat,
  double lng,
  String? name,
});

class DriverTrackingState {
  const DriverTrackingState({
    this.initialized = false,
    this.routeActive = false,
    this.foregroundStreaming = false,
    this.backgroundMode = false,
    this.socketConnected = false,
    this.permissionsGranted = false,
    this.routeId,
    this.routeManifestId,
    this.vanId,
    this.lastPointAt,
    this.lastLatitude,
    this.lastLongitude,
    this.lastSpeedKmh,
    this.lastHeading,
    this.pendingBufferCount = 0,
    this.geofenceRadiusMeters = 50,
    this.nearbyCount = 0,
    this.nearestChildName,
    this.nearestDistanceMeters,
    this.routeEtaSeconds,
    this.routeDistanceMeters,
    this.routePreviewMapUrl,
    this.routePreviewUpdatedAt,
    this.routeNextStopName,
    this.routePolyline = const [],
    this.routeRemainingStops = const [],
    this.routePlannedStops = const [],
    this.offRoute = false,
    this.routeRecalculating = false,
    this.warning,
    this.error,
  });

  final bool initialized;
  final bool routeActive;
  final bool foregroundStreaming;
  final bool backgroundMode;
  final bool socketConnected;
  final bool permissionsGranted;
  final int? routeId;
  final String? routeManifestId;
  final int? vanId;
  final DateTime? lastPointAt;
  final double? lastLatitude;
  final double? lastLongitude;
  final int? lastSpeedKmh;
  final int? lastHeading;
  final int pendingBufferCount;
  final int geofenceRadiusMeters;
  final int nearbyCount;
  final String? nearestChildName;
  final double? nearestDistanceMeters;
  final int? routeEtaSeconds;
  final double? routeDistanceMeters;
  final String? routePreviewMapUrl;
  final DateTime? routePreviewUpdatedAt;
  final String? routeNextStopName;
  final List<DriverTrackingLatLng> routePolyline;
  final List<DriverTrackingStopPoint> routeRemainingStops;
  final List<DriverTrackingStopPoint> routePlannedStops;
  final bool offRoute;
  final bool routeRecalculating;
  final String? warning;
  final String? error;

  bool get isTrackingInForeground => routeActive && foregroundStreaming;

  DriverTrackingState copyWith({
    bool? initialized,
    bool? routeActive,
    bool? foregroundStreaming,
    bool? backgroundMode,
    bool? socketConnected,
    bool? permissionsGranted,
    int? routeId,
    String? routeManifestId,
    int? vanId,
    DateTime? lastPointAt,
    double? lastLatitude,
    double? lastLongitude,
    int? lastSpeedKmh,
    int? lastHeading,
    int? pendingBufferCount,
    int? geofenceRadiusMeters,
    int? nearbyCount,
    String? nearestChildName,
    double? nearestDistanceMeters,
    int? routeEtaSeconds,
    double? routeDistanceMeters,
    String? routePreviewMapUrl,
    DateTime? routePreviewUpdatedAt,
    String? routeNextStopName,
    List<DriverTrackingLatLng>? routePolyline,
    List<DriverTrackingStopPoint>? routeRemainingStops,
    List<DriverTrackingStopPoint>? routePlannedStops,
    bool? offRoute,
    bool? routeRecalculating,
    String? warning,
    String? error,
    bool clearRoute = false,
    bool clearWarning = false,
    bool clearError = false,
    bool clearGeofence = false,
    bool clearRoutePreview = false,
    bool clearPosition = false,
  }) {
    return DriverTrackingState(
      initialized: initialized ?? this.initialized,
      routeActive: routeActive ?? this.routeActive,
      foregroundStreaming: foregroundStreaming ?? this.foregroundStreaming,
      backgroundMode: backgroundMode ?? this.backgroundMode,
      socketConnected: socketConnected ?? this.socketConnected,
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      routeId: clearRoute ? null : (routeId ?? this.routeId),
      routeManifestId: clearRoute
          ? null
          : (routeManifestId ?? this.routeManifestId),
      vanId: clearRoute ? null : (vanId ?? this.vanId),
      lastPointAt: clearPosition ? null : (lastPointAt ?? this.lastPointAt),
      lastLatitude: clearPosition ? null : (lastLatitude ?? this.lastLatitude),
      lastLongitude: clearPosition
          ? null
          : (lastLongitude ?? this.lastLongitude),
      lastSpeedKmh: clearPosition ? null : (lastSpeedKmh ?? this.lastSpeedKmh),
      lastHeading: clearPosition ? null : (lastHeading ?? this.lastHeading),
      pendingBufferCount: pendingBufferCount ?? this.pendingBufferCount,
      geofenceRadiusMeters: geofenceRadiusMeters ?? this.geofenceRadiusMeters,
      nearbyCount: clearGeofence ? 0 : (nearbyCount ?? this.nearbyCount),
      nearestChildName: clearGeofence
          ? null
          : (nearestChildName ?? this.nearestChildName),
      nearestDistanceMeters: clearGeofence
          ? null
          : (nearestDistanceMeters ?? this.nearestDistanceMeters),
      routeEtaSeconds: clearRoute || clearRoutePreview
          ? null
          : (routeEtaSeconds ?? this.routeEtaSeconds),
      routeDistanceMeters: clearRoute || clearRoutePreview
          ? null
          : (routeDistanceMeters ?? this.routeDistanceMeters),
      routePreviewMapUrl: clearRoute || clearRoutePreview
          ? null
          : (routePreviewMapUrl ?? this.routePreviewMapUrl),
      routePreviewUpdatedAt: clearRoute || clearRoutePreview
          ? null
          : (routePreviewUpdatedAt ?? this.routePreviewUpdatedAt),
      routeNextStopName: clearRoute || clearRoutePreview
          ? null
          : (routeNextStopName ?? this.routeNextStopName),
      routePolyline: clearRoute || clearRoutePreview
          ? const []
          : (routePolyline ?? this.routePolyline),
      routeRemainingStops: clearRoute || clearRoutePreview
          ? const []
          : (routeRemainingStops ?? this.routeRemainingStops),
      routePlannedStops: clearRoute || clearRoutePreview
          ? const []
          : (routePlannedStops ?? this.routePlannedStops),
      offRoute: clearRoute ? false : (offRoute ?? this.offRoute),
      routeRecalculating: clearRoute
          ? false
          : (routeRecalculating ?? this.routeRecalculating),
      warning: clearWarning ? null : (warning ?? this.warning),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
