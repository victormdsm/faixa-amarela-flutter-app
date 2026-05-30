import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/models/paginated_result.dart';
import '../../../core/network/api_exception.dart';

class DriverPortalRepository {
  DriverPortalRepository(this._dio);

  final Dio _dio;

  Future<PaginatedResult<Map<String, dynamic>>> clients(String authHeader) {
    return _getPaginated('/drivers/clients', authHeader);
  }

  Future<PaginatedResult<Map<String, dynamic>>> routes(String authHeader) {
    return _getPaginated('/drivers/routes', authHeader);
  }

  Future<Map<String, dynamic>> routePlanningOptions(String authHeader) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/drivers/routes/planning-options',
        options: Options(headers: {'Authorization': authHeader}),
      );
      return response.data ?? const <String, dynamic>{};
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> startAdhocRoute(
    String authHeader, {
    int? shiftId,
    required String tripMode,
    String? operationId,
    String? routeName,
    double? originLat,
    double? originLng,
    required List<Map<String, int>> selections,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/drivers/routes/start-adhoc',
        options: Options(headers: {'Authorization': authHeader}),
        data: {
          ...?_numEntry('shift_id', shiftId),
          'trip_mode': tripMode,
          ...?_stringEntry('operation_id', operationId),
          ...?_stringEntry('route_name', routeName),
          ...?_doubleEntry('origin_lat', originLat),
          ...?_doubleEntry('origin_lng', originLng),
          'selections': selections,
        },
      );
      return response.data ?? const <String, dynamic>{};
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<PaginatedResult<Map<String, dynamic>>> clientChildren(
    String authHeader,
    int clientId,
  ) {
    return _getPaginated('/drivers/clients/$clientId/children', authHeader);
  }

  Future<Map<String, dynamic>> profile(String authHeader) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/drivers/profile',
        options: Options(headers: {'Authorization': authHeader}),
      );
      return response.data ?? const <String, dynamic>{};
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> updateProfile(
    String authHeader, {
    required String name,
    String? email,
    String? cellPhone,
    String? password,
    String? passwordConfirmation,
    String? information,
    String? cnh,
    required List<int> schoolIds,
    required Map<int, List<int>> districtShiftMap,
    String? avatarImagePath,
    String? vehicleBrand,
    String? vehicleColor,
    String? vehicleYear,
    String? vehicleLicensePlate,
    String? vehicleImagePath,
  }) async {
    try {
      final hasAvatarImage =
          avatarImagePath != null && avatarImagePath.trim().isNotEmpty;
      final hasVehicleImage =
          vehicleImagePath != null && vehicleImagePath.trim().isNotEmpty;

      final payload = <String, dynamic>{
        'name': name,
        'email': email?.trim(),
        'cell_phone': cellPhone?.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
        'information': information?.trim(),
        'cnh': cnh?.trim(),
        'school_ids': jsonEncode(schoolIds),
        'district_shift_map': jsonEncode(
          districtShiftMap.entries
              .map((e) => {'district_id': e.key, 'shift_ids': e.value})
              .toList(growable: false),
        ),
        'vehicle_brand': vehicleBrand?.trim(),
        'vehicle_color': vehicleColor?.trim(),
        'vehicle_year': vehicleYear?.trim(),
        'vehicle_license_plate': vehicleLicensePlate?.trim(),
      };

      if (!hasAvatarImage && !hasVehicleImage) {
        final response = await _dio.post<Map<String, dynamic>>(
          '/drivers/profile',
          data: payload,
          options: Options(headers: {'Authorization': authHeader}),
        );
        return response.data ?? const <String, dynamic>{};
      }

      final form = FormData.fromMap(payload);
      if (hasAvatarImage) {
        final path = avatarImagePath;
        form.files.add(
          MapEntry('avatar_image', await MultipartFile.fromFile(path)),
        );
      }
      if (hasVehicleImage) {
        final path = vehicleImagePath;
        form.files.add(
          MapEntry('vehicle_image', await MultipartFile.fromFile(path)),
        );
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/drivers/profile',
        data: form,
        options: Options(
          headers: {'Authorization': authHeader},
          contentType: 'multipart/form-data',
        ),
      );
      return response.data ?? const <String, dynamic>{};
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> createClient(
    String authHeader, {
    int? parentId,
    int? childId,
    required String name,
    required String email,
    required String cpf,
    String? cellPhone,
    int? schoolId,
    int? districtId,
    int? shiftId,
    required String zipcode,
    required String street,
    required String number,
    String? reference,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/drivers/clients',
        options: Options(headers: {'Authorization': authHeader}),
        data: {
          ...?_numEntry('parent_id', parentId),
          ...?_numEntry('child_id', childId),
          'name': name,
          'email': email,
          'cpf': cpf,
          ...?_stringEntry('cell_phone', cellPhone),
          ...?_numEntry('school_id', schoolId),
          ...?_numEntry('district_id', districtId),
          ...?_numEntry('shift_id', shiftId),
          'address': {
            'zipcode': zipcode,
            'street': street,
            'number': number,
            ...?_stringEntry('reference', reference),
            ...?_numEntry('district_id', districtId),
          },
        },
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> lookupParentByCpf(
    String authHeader,
    String cpf,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/drivers/clients/lookup-parent',
        options: Options(headers: {'Authorization': authHeader}),
        queryParameters: {'cpf': cpf},
      );
      return response.data ?? const <String, dynamic>{};
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> unlinkClient(String authHeader, int clientId) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        '/drivers/clients/$clientId',
        options: Options(headers: {'Authorization': authHeader}),
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> updateClientInadimplency(
    String authHeader,
    int clientId, {
    double? amount,
    bool? isInadimplent,
    String? reason,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/drivers/clients/$clientId/inadimplency',
        options: Options(headers: {'Authorization': authHeader}),
        data: {
          ...?_doubleEntry('amount', amount),
          'is_inadimplent': ?isInadimplent,
          ...?_stringEntry('reason', reason),
        },
      );
      return response.data ?? const <String, dynamic>{};
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> createChild(
    String authHeader, {
    required int clientId,
    required String name,
    required int relativeId,
    String? sex,
    int? age,
    String? avatarImagePath,
    int? schoolId,
    int? shiftId,
  }) async {
    try {
      final hasAvatarImage =
          avatarImagePath != null && avatarImagePath.trim().isNotEmpty;
      final payload = <String, dynamic>{
        'name': name,
        'relative_id': relativeId,
        ...?_stringEntry('sex', sex),
        ...?_numEntry('age', age),
        ...?_numEntry('school_id', schoolId),
        ...?_numEntry('shift_id', shiftId),
      };

      final response = hasAvatarImage
          ? await _dio.post<Map<String, dynamic>>(
              '/drivers/clients/$clientId/children',
              options: Options(headers: {'Authorization': authHeader}),
              data: FormData.fromMap({
                ...payload,
                'avatar_image': await MultipartFile.fromFile(
                  avatarImagePath.trim(),
                ),
              }),
            )
          : await _dio.post<Map<String, dynamic>>(
              '/drivers/clients/$clientId/children',
              options: Options(headers: {'Authorization': authHeader}),
              data: payload,
            );
      return response.data ?? const <String, dynamic>{};
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> createChildAddress(
    String authHeader, {
    required int childId,
    required String zipcode,
    required String street,
    required String number,
    String? reference,
    int? districtId,
    int? cityId,
    String type = 'home',
    bool isDefault = false,
    String? latitude,
    String? longitude,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/drivers/children/$childId/addresses',
        options: Options(headers: {'Authorization': authHeader}),
        data: {
          'zipcode': zipcode,
          'street': street,
          'number': number,
          ...?_stringEntry('reference', reference),
          ...?_numEntry('district_id', districtId),
          ...?_numEntry('city_id', cityId),
          ...?_stringEntry('latitude', latitude),
          ...?_stringEntry('longitude', longitude),
          'type': type,
          'is_default': isDefault,
        },
      );
      return response.data ?? const <String, dynamic>{};
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> startRoute(
    String authHeader,
    int routeId, {
    int? vanId,
  }) async {
    return _postRouteAction(
      authHeader,
      routeId,
      'start',
      data: vanId == null ? null : <String, dynamic>{'van_id': vanId},
    );
  }

  Future<Map<String, dynamic>> finishRoute(
    String authHeader,
    int routeId,
  ) async {
    return _postRouteAction(authHeader, routeId, 'finish');
  }

  Future<Map<String, dynamic>> markBoarding(
    String authHeader,
    int routeId, {
    required int clientId,
  }) async {
    return _postRouteAction(
      authHeader,
      routeId,
      'boarding',
      data: <String, dynamic>{'client_id': clientId},
    );
  }

  Future<Map<String, dynamic>> markDisembarking(
    String authHeader,
    int routeId, {
    required int clientId,
  }) async {
    return _postRouteAction(
      authHeader,
      routeId,
      'disembarking',
      data: <String, dynamic>{'client_id': clientId},
    );
  }

  /// Notify a specific parent (arrived / delayed).
  Future<Map<String, dynamic>> notifyParent(
    String authHeader,
    int routeId, {
    required int clientId,
    required String type,
    String? message,
  }) async {
    return _postRouteAction(
      authHeader,
      routeId,
      'notify-parent',
      data: <String, dynamic>{
        'client_id': clientId,
        'type': type,
        'message': ?message,
      },
    );
  }

  /// Broadcast an emergency alert to ALL parents on the route.
  Future<Map<String, dynamic>> alertAllParents(
    String authHeader,
    int routeId, {
    required String type,
    String? message,
  }) async {
    return _postRouteAction(
      authHeader,
      routeId,
      'alert-all',
      data: <String, dynamic>{
        'type': type,
        'message': ?message,
      },
    );
  }

  /// Remove a student from the active route and recalculate.
  Future<Map<String, dynamic>> removeStudentFromRoute(
    String authHeader,
    int routeId, {
    required int clientId,
    double? lat,
    double? lng,
  }) async {
    return _postRouteAction(
      authHeader,
      routeId,
      'remove-student',
      data: <String, dynamic>{
        'client_id': clientId,
        'lat': ?lat,
        'lng': ?lng,
      },
    );
  }

  Future<Map<String, dynamic>> _postRouteAction(
    String authHeader,
    int routeId,
    String action, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/drivers/routes/$routeId/$action',
        data: data,
        options: Options(headers: {'Authorization': authHeader}),
      );
      return response.data ?? const <String, dynamic>{};
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<PaginatedResult<Map<String, dynamic>>> _getPaginated(
    String path,
    String authHeader,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        options: Options(headers: {'Authorization': authHeader}),
      );
      return PaginatedResult<Map<String, dynamic>>.fromJson(
        response.data ?? const <String, dynamic>{},
        (json) => json,
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Map<String, dynamic>? _stringEntry(String key, String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return {key: value};
  }

  Map<String, dynamic>? _numEntry(String key, int? value) {
    if (value == null) return null;
    return {key: value};
  }

  Map<String, dynamic>? _doubleEntry(String key, double? value) {
    if (value == null) return null;
    return {key: value};
  }
}
