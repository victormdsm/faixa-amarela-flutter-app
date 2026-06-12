import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/network_providers.dart';
import '../../../../core/storage/secure_token_storage.dart';
import '../../data/repositories/nestjs_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/activate_account_use_case.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/request_activation_link_use_case.dart';
import '../../domain/usecases/request_password_reset_use_case.dart';
import '../../domain/usecases/reset_password_use_case.dart';

part 'auth_providers.g.dart';

@riverpod
SecureTokenStorage secureTokenStorage(Ref ref) {
  return SecureTokenStorage();
}

@riverpod
AuthRepository authRepository(Ref ref) {
  return NestjsAuthRepository(
    ref.watch(dioProvider),
    ref.watch(secureTokenStorageProvider),
  );
}

@riverpod
LoginUseCase loginUseCase(Ref ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
}

@riverpod
RequestPasswordResetUseCase requestPasswordResetUseCase(Ref ref) {
  return RequestPasswordResetUseCase(ref.watch(authRepositoryProvider));
}

@riverpod
RequestActivationLinkUseCase requestActivationLinkUseCase(Ref ref) {
  return RequestActivationLinkUseCase(ref.watch(authRepositoryProvider));
}

@riverpod
ActivateAccountUseCase activateAccountUseCase(Ref ref) {
  return ActivateAccountUseCase(ref.watch(authRepositoryProvider));
}

@riverpod
ResetPasswordUseCase resetPasswordUseCase(Ref ref) {
  return ResetPasswordUseCase(ref.watch(authRepositoryProvider));
}
