import 'package:app_faixa_amarela/domain/repositories/enrollments_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChildLookupResult.fromJson', () {
    test('parses childUuid and multi-driver warning fields', () {
      final json = <String, dynamic>{
        'found': true,
        'childId': 5,
        'childUuid': '550e8400-e29b-41d4-a716-446655440000',
        'childName': 'Ana',
        'hasPendingEnrollment': false,
        'hasActiveEnrollmentWithOtherDriver': true,
        'activeDriverNames': ['Maria Motorista', 'José Silva'],
      };

      final result = ChildLookupResult.fromJson(json);

      expect(result.found, isTrue);
      expect(result.childId, 5);
      expect(result.childUuid, '550e8400-e29b-41d4-a716-446655440000');
      expect(result.hasActiveEnrollmentWithOtherDriver, isTrue);
      expect(result.activeDriverNames, ['Maria Motorista', 'José Silva']);
    });

    test('defaults multi-driver warning fields when absent', () {
      final result = ChildLookupResult.fromJson(const <String, dynamic>{
        'found': true,
        'childId': 5,
        'childName': 'Ana',
      });

      expect(result.childUuid, isNull);
      expect(result.hasActiveEnrollmentWithOtherDriver, isFalse);
      expect(result.activeDriverNames, isEmpty);
    });

    test('parses childUuid from nested child payload', () {
      final result = ChildLookupResult.fromJson(const <String, dynamic>{
        'found': true,
        'child': <String, dynamic>{
          'id': 5,
          'uuid': '550e8400-e29b-41d4-a716-446655440000',
          'name': 'Ana Silva',
        },
      });

      expect(result.childId, 5);
      expect(result.childUuid, '550e8400-e29b-41d4-a716-446655440000');
    });
  });
}
