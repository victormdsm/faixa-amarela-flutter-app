// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'1c1c046a87a1b548dccfe2922f61f3384fb9d174';

@ProviderFor(loginUseCase)
final loginUseCaseProvider = LoginUseCaseProvider._();

final class LoginUseCaseProvider
    extends $FunctionalProvider<LoginUseCase, LoginUseCase, LoginUseCase>
    with $Provider<LoginUseCase> {
  LoginUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loginUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loginUseCaseHash();

  @$internal
  @override
  $ProviderElement<LoginUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LoginUseCase create(Ref ref) {
    return loginUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoginUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoginUseCase>(value),
    );
  }
}

String _$loginUseCaseHash() => r'e082833fd1fc26be8c5fac08d612713cb2c18a17';

@ProviderFor(requestPasswordResetUseCase)
final requestPasswordResetUseCaseProvider =
    RequestPasswordResetUseCaseProvider._();

final class RequestPasswordResetUseCaseProvider
    extends
        $FunctionalProvider<
          RequestPasswordResetUseCase,
          RequestPasswordResetUseCase,
          RequestPasswordResetUseCase
        >
    with $Provider<RequestPasswordResetUseCase> {
  RequestPasswordResetUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'requestPasswordResetUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$requestPasswordResetUseCaseHash();

  @$internal
  @override
  $ProviderElement<RequestPasswordResetUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RequestPasswordResetUseCase create(Ref ref) {
    return requestPasswordResetUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RequestPasswordResetUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RequestPasswordResetUseCase>(value),
    );
  }
}

String _$requestPasswordResetUseCaseHash() =>
    r'4fb72108f0f691d292985b252dc367b5d2fbf8e9';

@ProviderFor(requestActivationLinkUseCase)
final requestActivationLinkUseCaseProvider =
    RequestActivationLinkUseCaseProvider._();

final class RequestActivationLinkUseCaseProvider
    extends
        $FunctionalProvider<
          RequestActivationLinkUseCase,
          RequestActivationLinkUseCase,
          RequestActivationLinkUseCase
        >
    with $Provider<RequestActivationLinkUseCase> {
  RequestActivationLinkUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'requestActivationLinkUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$requestActivationLinkUseCaseHash();

  @$internal
  @override
  $ProviderElement<RequestActivationLinkUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RequestActivationLinkUseCase create(Ref ref) {
    return requestActivationLinkUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RequestActivationLinkUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RequestActivationLinkUseCase>(value),
    );
  }
}

String _$requestActivationLinkUseCaseHash() =>
    r'47e1884afcbec0a57b93bab33afdc28fe72efcce';
