import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../storage/secure_token_storage.dart';
import 'api_client.dart';
import 'auth_interceptor.dart';
import 'backend_config.dart';
import 'nestjs_response_unwrap_interceptor.dart';
import 'safe_log_interceptor.dart';

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

  dio.interceptors.add(NestjsResponseUnwrapInterceptor());
  dio.interceptors.add(
    AuthInterceptor(dio: dio, secureStorage: SecureTokenStorage()),
  );
  dio.interceptors.add(SafeLogInterceptor());

  return dio;
}

@riverpod
ApiClient apiClient(Ref ref) {
  return ApiClient(ref.watch(dioProvider));
}
