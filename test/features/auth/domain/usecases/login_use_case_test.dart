import 'package:app_faixa_amarela/features/auth/domain/entities/auth_session.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_user.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/user_role.dart';
import 'package:app_faixa_amarela/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_faixa_amarela/features/auth/domain/usecases/login_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    useCase = LoginUseCase(repository);
  });

  test('calls repository signIn with correct params', () async {
    final session = AuthSession(
      accessToken: 'token',
      tokenType: 'Bearer',
      user: AuthUser(id: 1, name: 'User', email: 'u@e.com', roles: ['user']),
    );

    when(
      () => repository.signIn(
        email: 'test@email.com',
        password: 'secret',
        role: UserRole.parent,
      ),
    ).thenAnswer((_) async => session);

    final result = await useCase(
      email: 'test@email.com',
      password: 'secret',
      role: UserRole.parent,
    );

    expect(result.accessToken, 'token');
    verify(
      () => repository.signIn(
        email: 'test@email.com',
        password: 'secret',
        role: UserRole.parent,
      ),
    ).called(1);
  });
}
