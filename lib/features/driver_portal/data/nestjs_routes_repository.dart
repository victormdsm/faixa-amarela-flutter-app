import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/dto/route_manifest_dto.dart';
import '../../../../domain/models/route_manifest.dart';
import '../../../../domain/repositories/routes_repository.dart';

class NestjsRoutesRepository implements RoutesRepository {
  NestjsRoutesRepository(this._dio);

  final Dio _dio;

  @override
  Future<RoutePlanningOptions> getPlanningOptions() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/driver/routes/planning-options',
      );
      return RoutePlanningOptions.fromJson(
        _unwrapData(response.data) ?? const <String, dynamic>{},
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> listDriverRoutes() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/driver/routes');
      final data = _unwrapData(response.data);
      final list = data is List ? data as List<dynamic> : const <dynamic>[];
      return list
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<RouteManifest> startRoute() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/driver/routes/start',
        data: const <String, dynamic>{},
      );
      final routeData = _unwrapData(response.data) ?? const <String, dynamic>{};
      return _parseRouteResponse(routeData);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> finishRoute(int id) async {
    try {
      await _dio.post<Map<String, dynamic>>('/driver/routes/$id/finish');
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<RouteManifest?> getActiveRoute() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/driver/routes/active',
      );
      final routeData = _unwrapData(response.data);
      if (routeData == null || routeData.isEmpty) return null;
      return _parseRouteResponse(routeData);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<RouteStop> markBoarding(int routeId, int childId) async {
    try {
      await _dio.post<void>(
        '/driver/routes/$routeId/boarding',
        data: {'childId': childId},
      );
      return _findStopAfterAction(childId, StopStatus.boarded);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<RouteStop> markDisembarking(int routeId, int childId) async {
    try {
      await _dio.post<void>(
        '/driver/routes/$routeId/disembarking',
        data: {'childId': childId},
      );
      return _findStopAfterAction(childId, StopStatus.disembarked);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<List<RouteStop>> bulkDisembarkAtSchool(
    int routeId,
    int schoolId,
  ) async {
    try {
      await _dio.post<void>(
        '/driver/routes/$routeId/school-bulk-disembark',
        data: {'schoolId': schoolId},
      );
      final active = await getActiveRoute();
      return active?.stops
              .where((stop) => stop.status == StopStatus.disembarked)
              .toList(growable: false) ??
          const [];
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> removeStudent(int routeId, int childId) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/driver/routes/$routeId/remove-student',
        data: {'childId': childId},
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> notifyParent(
    int routeId,
    int childId,
    String type, {
    String? message,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/driver/routes/$routeId/notify-parent',
        data: _messagePayload(
          {'childId': childId, 'type': type},
          message,
        ),
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> alertAll(int routeId, String type, {String? message}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/driver/routes/$routeId/alert-all',
        data: _messagePayload({'type': type}, message),
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// Extrai o payload do envelope { data: ... } retornado pelo NestJS.
  Map<String, dynamic>? _unwrapData(Map<String, dynamic>? response) {
    if (response == null) return null;
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return response;
  }

  /// Constroi um lookup childId -> dados da crianca a partir de
  /// document.children (contrato NestJS).
  Map<int, Map<String, dynamic>> _buildChildLookup(
    Map<String, dynamic> routeData,
  ) {
    final manifest = routeData['manifest'];
    if (manifest is! Map) return const {};

    final document = manifest['document'];
    if (document is! Map) return const {};

    final children = document['children'];
    if (children is! List) return const {};

    final lookup = <int, Map<String, dynamic>>{};
    for (final child in children.whereType<Map>()) {
      final childIdValue = child['childId'] ?? child['id'];
      final childId = childIdValue is num
          ? childIdValue.toInt()
          : int.tryParse(childIdValue.toString()) ?? 0;
      if (childId > 0) {
        lookup[childId] = Map<String, dynamic>.from(child);
      }
    }
    return lookup;
  }

  RouteManifest _parseRouteResponse(Map<String, dynamic> routeData) {
    final childLookup = _buildChildLookup(routeData);

    final manifestData = routeData['manifest'];
    if (manifestData is Map<String, dynamic>) {
      return RouteManifestDto.fromJson(
        manifestData,
        childLookup: childLookup,
      ).toDomain();
    }
    if (manifestData is Map) {
      return RouteManifestDto.fromJson(
        Map<String, dynamic>.from(manifestData),
        childLookup: childLookup,
      ).toDomain();
    }

    return RouteManifestDto.fromJson(
      routeData,
      childLookup: childLookup,
    ).toDomain();
  }

  Map<String, dynamic> _messagePayload(
    Map<String, dynamic> base,
    String? message,
  ) {
    final trimmed = message?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      base['message'] = trimmed;
    }
    return base;
  }

  Future<RouteStop> _findStopAfterAction(
    int childId,
    StopStatus fallbackStatus,
  ) async {
    final active = await getActiveRoute();
    RouteStop? stop;
    for (final candidate in active?.stops ?? const <RouteStop>[]) {
      if (candidate.childId == childId) {
        stop = candidate;
        break;
      }
    }
    if (stop != null) return stop;

    return RouteStop(
      id: 0,
      childId: childId,
      childName: '',
      schoolName: '',
      address: '',
      sequence: 0,
      status: fallbackStatus,
    );
  }
}
