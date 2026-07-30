import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/dto/child_dto.dart';
import '../../../domain/models/address_suggestion.dart';
import '../../../domain/models/child.dart';
import '../../../domain/repositories/children_repository.dart';

class NestjsChildrenRepository implements ChildrenRepository {
  NestjsChildrenRepository(this._dio);

  final Dio _dio;

  /// CPF vai só com dígitos; RG vai como digitado (trim), pois pode conter
  /// letra (dígito verificador) e pontuação — o backend valida 5-14 chars.
  String _cleanDocument(String document, String documentType) {
    if (documentType == ChildDocumentType.rg) return document.trim();
    return document.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// `documentState` só entra no payload quando o tipo é RG — o backend o
  /// rejeita para CPF.
  String? _rgState(String documentType, String? documentState) {
    if (documentType != ChildDocumentType.rg) return null;
    final state = (documentState ?? '').trim().toUpperCase();
    return state.isEmpty ? null : state;
  }

  AppFailure _mapException(Object error) {
    final apiException = error is ApiException
        ? error
        : ApiException.fromDio(error);

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return TimeoutFailure(message: apiException.message);
        case DioExceptionType.connectionError:
          return NetworkFailure(message: apiException.message);
        default:
          break;
      }
    }

    return switch (apiException.statusCode) {
      401 => AuthFailure(message: apiException.message),
      403 => ForbiddenFailure(message: apiException.message),
      404 => NotFoundFailure(message: apiException.message),
      422 => ValidationFailure(message: apiException.message),
      _
          when apiException.statusCode != null &&
              apiException.statusCode! >= 500 =>
        ServerFailure(message: apiException.message),
      _ => ServerFailure(message: apiException.message),
    };
  }

  @override
  Future<List<Child>> getChildren() async {
    try {
      // The NestJS response unwrap interceptor replaces the body with the
      // `data` payload, so the response is a List<dynamic> directly.
      final response = await _dio.get<List<dynamic>>('/parent/children');
      final raw = response.data ?? const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map((e) => ChildDto.fromJson(e).toDomain())
          .toList(growable: false);
    } catch (e) {
      debugPrint('[NestjsChildrenRepository.getChildren] ERRO: $e');
      throw _mapException(e);
    }
  }

  @override
  Future<Child?> getChildById(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/parent/children/$id',
      );
      final data = response.data;
      if (data == null) return null;
      return ChildDto.fromJson(data).toDomain();
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<Child> createChild({
    required String name,
    required String document,
    String documentType = ChildDocumentType.cpf,
    String? documentState,
    required int? schoolId,
    required int? shiftId,
    required ChildAddress address,
  }) async {
    try {
      final rgState = _rgState(documentType, documentState);
      final response = await _dio.post<Map<String, dynamic>>(
        '/parent/children',
        data: <String, dynamic>{
          'name': name.trim(),
          'document': _cleanDocument(document, documentType),
          'documentType': documentType,
          'documentState': ?rgState,
          if (schoolId != null && schoolId > 0) 'schoolId': schoolId,
          if (shiftId != null && shiftId > 0) 'shiftId': shiftId,
        },
      );
      final body = response.data;
      if (body == null) {
        throw const ServerFailure(message: 'Resposta vazia do servidor.');
      }
      final child = ChildDto.fromJson(body).toDomain();

      await _createAddress(child.id, address);

      return child;
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<Child> updateChild({
    required int id,
    String? name,
    String? document,
    String? documentType,
    String? documentState,
    int? schoolId,
    int? shiftId,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null) payload['name'] = name.trim();
      if (document != null) {
        payload['document'] = _cleanDocument(
          document,
          documentType ?? ChildDocumentType.cpf,
        );
      }
      if (documentType != null) payload['documentType'] = documentType;
      final rgState = _rgState(documentType ?? '', documentState);
      if (rgState != null) payload['documentState'] = rgState;
      if (schoolId != null) {
        payload['schoolId'] = schoolId > 0 ? schoolId : null;
      }
      if (shiftId != null) payload['shiftId'] = shiftId > 0 ? shiftId : null;

      final response = await _dio.put<Map<String, dynamic>>(
        '/parent/children/$id',
        data: payload,
      );
      final data = response.data;
      if (data == null) {
        throw const ServerFailure(message: 'Resposta vazia do servidor.');
      }
      return ChildDto.fromJson(data).toDomain();
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> deleteChild(int id) async {
    try {
      await _dio.delete(
        '/parent/children/$id',
        options: Options(contentType: null),
      );
    } catch (e) {
      throw _mapException(e);
    }
  }

  /// Campos de endereço enviados no create/update. city/state/neighborhood
  /// são opcionais no DTO do backend e só vão quando preenchidos.
  ///
  /// `reference` (complemento) só entra quando [includeReference] é true:
  /// no update, o backend aplica `reference` sempre que a chave vem — até
  /// `null` apaga o valor gravado. Omitir a chave preserva o dado (APP-01).
  ///
  /// APP-27: no update ([explicitNeighborhoodNull]), bairro esvaziado vai
  /// como `neighborhood: null` explícito — o backend só altera o campo
  /// quando a chave vem no payload, então omitir preservaria o valor antigo.
  Map<String, dynamic> _addressPayload(
    ChildAddress address,
    bool isDefault, {
    required bool includeReference,
    bool explicitNeighborhoodNull = false,
  }) {
    final district = (address.district ?? '').trim();
    return <String, dynamic>{
      'zipcode': (address.zipCode ?? '').trim(),
      'street': address.street.trim(),
      'number': address.number.trim(),
      if (includeReference) 'reference': address.complement?.trim(),
      'type': 'home',
      'isDefault': isDefault,
      if (district.isNotEmpty)
        'neighborhood': district
      else if (explicitNeighborhoodNull)
        'neighborhood': null,
      if ((address.city ?? '').trim().isNotEmpty) 'city': address.city!.trim(),
      if ((address.state ?? '').trim().isNotEmpty)
        'state': address.state!.trim(),
      if (address.latitude != null && address.longitude != null) ...{
        'latitude': address.latitude,
        'longitude': address.longitude,
      },
    };
  }

  Future<void> _createAddress(
    int childId,
    ChildAddress address, {
    bool isDefault = true,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/parent/children/$childId/addresses',
      // Create: o complemento só vai quando o usuário digitou algo — um
      // endereço novo sem complemento não precisa da chave (APP-01).
      data: _addressPayload(
        address,
        isDefault,
        includeReference: (address.complement ?? '').trim().isNotEmpty,
      ),
    );
  }

  @override
  Future<({double latitude, double longitude, String? label})?> geocodeAddress(
    String text,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/parent/addresses/geocode',
        queryParameters: {'text': text},
      );
      final data = response.data;
      if (data == null) return null;
      final latitude = (data['latitude'] as num?)?.toDouble();
      final longitude = (data['longitude'] as num?)?.toDouble();
      if (latitude == null || longitude == null) return null;
      return (
        latitude: latitude,
        longitude: longitude,
        label: data['label']?.toString(),
      );
    } catch (e) {
      // 404 (não localizado) e falhas do geocoder viram AppFailure com a
      // mensagem amigável do backend — o chamador exibe e oferece retry.
      throw _mapException(e);
    }
  }

  @override
  Future<List<AddressSuggestion>> autocompleteAddress(
    String text, {
    String? city,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/parent/addresses/autocomplete',
        queryParameters: <String, dynamic>{
          'text': text,
          if ((city ?? '').trim().isNotEmpty) 'city': city!.trim(),
        },
      );
      // O interceptor de unwrap já entrega a lista; o fallback cobre o
      // envelope cru `{ data: [...] }` caso o contrato chegue intacto.
      final raw = response.data;
      final List<dynamic> list = switch (raw) {
        final List<dynamic> l => l,
        final Map<String, dynamic> m when m['data'] is List =>
          m['data'] as List<dynamic>,
        _ => const <dynamic>[],
      };
      return list
          .whereType<Map<String, dynamic>>()
          .map(AddressSuggestion.fromJson)
          .where((s) => s.label.trim().isNotEmpty)
          .toList(growable: false);
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<AddressSuggestion> reverseAddress({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/parent/addresses/reverse',
        queryParameters: {'lat': latitude, 'lon': longitude},
      );
      final data = response.data;
      if (data == null) {
        throw const ServerFailure(message: 'Resposta vazia do servidor.');
      }
      return AddressSuggestion.fromJson(data);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw _mapException(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getChildAddresses(int childId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/parent/children/$childId/addresses',
      );
      return (response.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> updateChildAddress({
    required int childId,
    required int addressId,
    required ChildAddress address,
    bool includeReference = false,
  }) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        '/parent/children/$childId/addresses/$addressId',
        data: _addressPayload(
          address,
          true,
          includeReference: includeReference,
          // Update: bairro esvaziado precisa ir como null explícito (APP-27).
          explicitNeighborhoodNull: true,
        ),
      );
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> createChildAddress({
    required int childId,
    required ChildAddress address,
    bool isDefault = false,
  }) async {
    try {
      await _createAddress(childId, address, isDefault: isDefault);
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> deleteChildAddress({
    required int childId,
    required int addressId,
  }) async {
    try {
      await _dio.delete(
        '/parent/children/$childId/addresses/$addressId',
        options: Options(contentType: null),
      );
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> setChildAddressDefault({
    required int childId,
    required int addressId,
  }) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        '/parent/children/$childId/addresses/$addressId',
        data: const <String, dynamic>{'isDefault': true},
      );
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<Child> uploadChildPhoto({
    required int childId,
    required String filePath,
  }) async {
    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/parent/children/$childId/photo',
        data: form,
      );
      final data = response.data;
      if (data == null) {
        throw const ServerFailure(message: 'Resposta vazia do servidor.');
      }
      return ChildDto.fromJson(data).toDomain();
    } catch (e) {
      throw _mapException(e);
    }
  }
}
