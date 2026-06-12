import 'package:app_faixa_amarela/core/network/backend_config.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore_for_file: do_not_use_environment

void main() {
  group('BackendConfig.apiBaseUrlFrom', () {
    test('returns dart-define value normalized with /api/v1 when provided', () {
      const base = 'https://api.example.com';
      expect(
        BackendConfig.apiBaseUrlFrom(base),
        'https://api.example.com/api/v1',
      );
    });

    test('preserves existing /api/v1 suffix from dart-define', () {
      const base = 'https://api.example.com/api/v1';
      expect(
        BackendConfig.apiBaseUrlFrom(base),
        'https://api.example.com/api/v1',
      );
    });

    test('removes trailing slash before appending /api/v1', () {
      const base = 'https://api.example.com/';
      expect(
        BackendConfig.apiBaseUrlFrom(base),
        'https://api.example.com/api/v1',
      );
    });
  });
}
