import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/network_providers.dart';
import '../../data/repositories/laravel_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/request_activation_link_use_case.dart';
import '../../domain/usecases/request_password_reset_use_case.dart';

part 'auth_providers.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return LaravelAuthRepository(ref.watch(dioProvider));
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
