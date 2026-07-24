import 'package:app_faixa_amarela/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthUser role helpers', () {
    test('isParent recognizes parent and user roles', () {
      expect(
        const AuthUser(id: 1, name: 'P', email: 'p@email.com', roles: ['parent']).isParent,
        isTrue,
      );
      expect(
        const AuthUser(id: 1, name: 'P', email: 'p@email.com', roles: ['user']).isParent,
        isTrue,
      );
      expect(
        const AuthUser(id: 1, name: 'P', email: 'p@email.com', roles: ['driver']).isParent,
        isFalse,
      );
    });

    test('isDriver recognizes driver role case-insensitively', () {
      expect(
        const AuthUser(id: 1, name: 'D', email: 'd@email.com', roles: ['driver']).isDriver,
        isTrue,
      );
      expect(
        const AuthUser(id: 1, name: 'D', email: 'd@email.com', roles: ['DRIVER']).isDriver,
        isTrue,
      );
      expect(
        const AuthUser(id: 1, name: 'D', email: 'd@email.com', roles: ['parent']).isDriver,
        isFalse,
      );
    });

    test('isDriverAppRole matches isDriver', () {
      final driver = AuthUser(
        id: 1,
        name: 'D',
        email: 'd@email.com',
        roles: const ['driver'],
      );
      expect(driver.isDriverAppRole, isTrue);
      expect(driver.isDriverAppRole, driver.isDriver);

      final parent = AuthUser(
        id: 2,
        name: 'P',
        email: 'p@email.com',
        roles: const ['parent'],
      );
      expect(parent.isDriverAppRole, isFalse);
    });
  });
}
