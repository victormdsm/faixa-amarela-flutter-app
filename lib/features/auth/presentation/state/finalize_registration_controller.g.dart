// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finalize_registration_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FinalizeRegistrationController)
final finalizeRegistrationControllerProvider =
    FinalizeRegistrationControllerProvider._();

final class FinalizeRegistrationControllerProvider
    extends
        $NotifierProvider<
          FinalizeRegistrationController,
          FinalizeRegistrationState
        > {
  FinalizeRegistrationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'finalizeRegistrationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$finalizeRegistrationControllerHash();

  @$internal
  @override
  FinalizeRegistrationController create() => FinalizeRegistrationController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FinalizeRegistrationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FinalizeRegistrationState>(value),
    );
  }
}

String _$finalizeRegistrationControllerHash() =>
    r'6258767240ee74c1b49a7ae0d476d47ec65bae05';

abstract class _$FinalizeRegistrationController
    extends $Notifier<FinalizeRegistrationState> {
  FinalizeRegistrationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<FinalizeRegistrationState, FinalizeRegistrationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FinalizeRegistrationState, FinalizeRegistrationState>,
              FinalizeRegistrationState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
