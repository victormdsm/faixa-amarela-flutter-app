import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app_faixa_amarela/core/network/api_exception.dart';
import 'package:app_faixa_amarela/features/auth/data/repositories/laravel_auth_repository.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/user_role.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LaravelAuthRepository.signIn', () {
    test('bloqueia conta admin no login do app sem expor a role', () async {
      final repository = LaravelAuthRepository(
        _dioWithResponse({
          'access_token': 'admin-token',
          'token_type': 'Bearer',
          'user': {
            'id': 1,
            'name': 'Admin',
            'email': 'admin@example.com',
            'role': 'admin',
          },
        }),
      );

      final result = repository.signIn(
        email: 'admin@example.com',
        password: 'secret123',
        role: UserRole.driver,
      );

      await expectLater(
        result,
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 403)
              .having(
                (error) => error.message,
                'message',
                'Meio de acesso incorreto. Use o canal adequado para sua conta.',
              )
              .having(
                (error) => error.message.toLowerCase(),
                'message',
                isNot(contains('admin')),
              ),
        ),
      );
    });

    test('mantem login de motorista valido', () async {
      final repository = LaravelAuthRepository(
        _dioWithResponse({
          'access_token': 'driver-token',
          'token_type': 'Bearer',
          'user': {
            'id': 2,
            'name': 'Motorista',
            'email': 'driver@example.com',
            'role': 'driver',
          },
        }),
      );

      final session = await repository.signIn(
        email: 'driver@example.com',
        password: 'secret123',
        role: UserRole.driver,
      );

      expect(session.accessToken, 'driver-token');
      expect(session.user.isDriverAppRole, isTrue);
    });
  });
}

Dio _dioWithResponse(Map<String, dynamic> data) {
  return Dio()..httpClientAdapter = _JsonResponseAdapter(data);
}

class _JsonResponseAdapter implements HttpClientAdapter {
  _JsonResponseAdapter(this.data);

  final Map<String, dynamic> data;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(data),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
