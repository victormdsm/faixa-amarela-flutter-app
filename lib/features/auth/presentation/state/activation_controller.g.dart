// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activation_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActivationController)
final activationControllerProvider = ActivationControllerProvider._();

final class ActivationControllerProvider
    extends $NotifierProvider<ActivationController, ActivationState> {
  ActivationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activationControllerHash();

  @$internal
  @override
  ActivationController create() => ActivationController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActivationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActivationState>(value),
    );
  }
}

String _$activationControllerHash() =>
    r'4046e048fe7590f12df871b45b5737f82f4f068d';

abstract class _$ActivationController extends $Notifier<ActivationState> {
  ActivationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ActivationState, ActivationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ActivationState, ActivationState>,
              ActivationState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
