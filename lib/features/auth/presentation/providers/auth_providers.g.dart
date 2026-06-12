// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(secureTokenStorage)
final secureTokenStorageProvider = SecureTokenStorageProvider._();

final class SecureTokenStorageProvider
    extends
        $FunctionalProvider<
          SecureTokenStorage,
          SecureTokenStorage,
          SecureTokenStorage
        >
    with $Provider<SecureTokenStorage> {
  SecureTokenStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'secureTokenStorageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$secureTokenStorageHash();

  @$internal
  @override
  $ProviderElement<SecureTokenStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SecureTokenStorage create(Ref ref) {
    return secureTokenStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SecureTokenStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SecureTokenStorage>(value),
    );
  }
}

String _$secureTokenStorageHash() =>
    r'e5e69a815ffd6b90eeab1a23c33f70a8c9c2675c';

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

String _$authRepositoryHash() => r'5432e08d0d78de6143bf05a83c53aa98b1dfe1a3';

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

@ProviderFor(activateAccountUseCase)
final activateAccountUseCaseProvider = ActivateAccountUseCaseProvider._();

final class ActivateAccountUseCaseProvider
    extends
        $FunctionalProvider<
          ActivateAccountUseCase,
          ActivateAccountUseCase,
          ActivateAccountUseCase
        >
    with $Provider<ActivateAccountUseCase> {
  ActivateAccountUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activateAccountUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activateAccountUseCaseHash();

  @$internal
  @override
  $ProviderElement<ActivateAccountUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ActivateAccountUseCase create(Ref ref) {
    return activateAccountUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActivateAccountUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActivateAccountUseCase>(value),
    );
  }
}

String _$activateAccountUseCaseHash() =>
    r'158a07989c17bbbaf33e1bc2d8a65091be9acb50';

@ProviderFor(resetPasswordUseCase)
final resetPasswordUseCaseProvider = ResetPasswordUseCaseProvider._();

final class ResetPasswordUseCaseProvider
    extends
        $FunctionalProvider<
          ResetPasswordUseCase,
          ResetPasswordUseCase,
          ResetPasswordUseCase
        >
    with $Provider<ResetPasswordUseCase> {
  ResetPasswordUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resetPasswordUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resetPasswordUseCaseHash();

  @$internal
  @override
  $ProviderElement<ResetPasswordUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ResetPasswordUseCase create(Ref ref) {
    return resetPasswordUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResetPasswordUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResetPasswordUseCase>(value),
    );
  }
}

String _$resetPasswordUseCaseHash() =>
    r'9a9295df0d0c380a87de0d22b3e8fd0b0d363386';
