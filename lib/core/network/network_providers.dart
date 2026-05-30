import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'api_client.dart';
import 'backend_config.dart';

part 'network_providers.g.dart';

@riverpod
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      baseUrl: BackendConfig.apiBaseUrl,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: false,
      requestHeader: false,
      responseHeader: false,
    ),
  );

  return dio;
}

@riverpod
ApiClient apiClient(Ref ref) {
  return ApiClient(ref.watch(dioProvider));
}
