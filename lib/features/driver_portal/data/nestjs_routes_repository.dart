import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/dto/route_manifest_dto.dart';
import '../../../domain/models/route_manifest.dart';
import '../../../domain/repositories/routes_repository.dart';

class NestjsRoutesRepository implements RoutesRepository {
  NestjsRoutesRepository(this._dio);

  final Dio _dio;

  @override
  Future<RoutePlanningOptions> getPlanningOptions({
    int? shiftId,
    String? period,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/driver/routes/planning-options',
        queryParameters: <String, dynamic>{
          'shiftId': ?shiftId,
          'period': ?period,
        },
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
      // Usamos <dynamic> porque o interceptor desembrulha { data: [...] }
      // e o Dio nao consegue fazer cast de List para Map<String, dynamic>.
      final response = await _dio.get<dynamic>('/driver/routes');
      final raw = response.data;
      final List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic> && raw['data'] is List) {
        list = raw['data'] as List<dynamic>;
      } else {
        list = const <dynamic>[];
      }
      return list
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<RouteManifest> startRoute({
    int? shiftId,
    String? period,
    List<int>? childIds,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/driver/routes/start',
        data: <String, dynamic>{
          'shiftId': ?shiftId,
          'period': ?period,
          // Enviado apenas quando o motorista alterou a seleção padrão —
          // backends anteriores ao contrato rejeitam campos desconhecidos
          // (ValidationPipe com forbidNonWhitelisted).
          'childIds': ?childIds,
        },
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
      await _dio.post<Map<String, dynamic>>(
        '/driver/routes/$id/finish',
        data: const <String, dynamic>{},
      );
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
  Future<RouteStop> markAbsent(int routeId, int childId) async {
    try {
      await _dio.post<void>(
        '/driver/routes/$routeId/absent',
        data: {'childId': childId},
      );
      return _findStopAfterAction(childId, StopStatus.absent);
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
        data: _messagePayload({'childId': childId, 'type': type}, message),
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

  /// Normaliza a resposta já desembrulhada pelo interceptor global.
  ///
  /// Antes o backend envolvia o payload em `{ data: ... }`; agora o
  /// [NestjsResponseUnwrapInterceptor] remove esse envelope antes de chegar
  /// aos repositories, então apenas garantimos o tipo correto.
  Map<String, dynamic>? _unwrapData(Map<String, dynamic>? response) {
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
      childName: 'Aluno $childId',
      schoolName: '',
      address: '',
      sequence: 0,
      status: fallbackStatus,
    );
  }
}
