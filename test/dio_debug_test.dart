// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debug dio login', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api/v1'));
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/user/login',
        data: {
          'email': 'aoextremogames@gmail.com',
          'password': 'Escolabetta1234',
        },
      );
      print('Status: ${response.statusCode}');
      print('Data: ${response.data}');
    } catch (e) {
      if (e is DioException) {
        print('DioError type: ${e.type}');
        print('Message: ${e.message}');
        print('Response status: ${e.response?.statusCode}');
        print('Response data: ${e.response?.data}');
        print('Request path: ${e.requestOptions.path}');
        print('Request baseUrl: ${e.requestOptions.baseUrl}');
      } else {
        print('Error: $e');
      }
      fail('Request failed');
    }
  });
}
