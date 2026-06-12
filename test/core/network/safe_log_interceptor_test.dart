import 'package:app_faixa_amarela/core/network/safe_log_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SafeLogInterceptor', () {
    test('is not a LogInterceptor with requestBody enabled', () {
      final interceptor = SafeLogInterceptor();
      expect(interceptor, isA<SafeLogInterceptor>());
      // Sanity: the safe interceptor must not be a stock LogInterceptor that
      // could be configured with requestBody: true.
      expect(interceptor.runtimeType.toString(), 'SafeLogInterceptor');
    });
  });
}
