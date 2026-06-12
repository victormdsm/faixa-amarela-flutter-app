import 'package:app_faixa_amarela/features/auth/data/repositories/nestjs_auth_repository.dart';
import 'package:app_faixa_amarela/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('authRepositoryProvider', () {
    test('resolves to NestjsAuthRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repository = container.read(authRepositoryProvider);

      expect(repository, isA<NestjsAuthRepository>());
    });
  });
}
