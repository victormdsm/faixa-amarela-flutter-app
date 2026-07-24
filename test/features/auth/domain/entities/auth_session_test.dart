import 'package:app_faixa_amarela/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthSession', () {
    test('parses refresh token and expiration from camelCase response', () {
      final session = AuthSession.fromJson({
        'accessToken': 'access',
        'refreshToken': 'refresh',
        'tokenType': 'Bearer',
        'expiresIn': 3600,
        'refreshExpiresIn': 604800,
        'user': {
          'id': 1,
          'name': 'User',
          'email': 'user@email.com',
          'roles': ['user'],
        },
      });

      expect(session.accessToken, 'access');
      expect(session.refreshToken, 'refresh');
      expect(session.tokenType, 'Bearer');
      expect(session.hasRefreshToken, true);
      expect(session.expiresAt, isNotNull);
      expect(session.refreshExpiresAt, isNotNull);
    });

    test('parses refresh token from camelCase response (compact)', () {
      final session = AuthSession.fromJson({
        'accessToken': 'access',
        'refreshToken': 'refresh',
        'tokenType': 'Bearer',
        'expiresIn': 3600,
        'refreshExpiresIn': 604800,
        'user': {
          'id': 1,
          'name': 'User',
          'email': 'user@email.com',
          'roles': ['user'],
        },
      });

      expect(session.refreshToken, 'refresh');
      expect(session.hasRefreshToken, true);
    });

    test('reports no refresh token when absent', () {
      final session = AuthSession.fromJson({
        'accessToken': 'access',
        'tokenType': 'Bearer',
        'expiresIn': 3600,
        'user': {
          'id': 1,
          'name': 'User',
          'email': 'user@email.com',
          'roles': ['user'],
        },
      });

      expect(session.hasRefreshToken, false);
    });
  });
}
