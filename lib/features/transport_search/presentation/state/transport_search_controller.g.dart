// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transport_search_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TransportSearchController)
final transportSearchControllerProvider = TransportSearchControllerProvider._();

final class TransportSearchControllerProvider
    extends
        $NotifierProvider<
          TransportSearchController,
          TransportSearchFiltersState
        > {
  TransportSearchControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transportSearchControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transportSearchControllerHash();

  @$internal
  @override
  TransportSearchController create() => TransportSearchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransportSearchFiltersState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransportSearchFiltersState>(value),
    );
  }
}

String _$transportSearchControllerHash() =>
    r'b47b4a535c911133e60ab215785cc70911547ab1';

abstract class _$TransportSearchController
    extends $Notifier<TransportSearchFiltersState> {
  TransportSearchFiltersState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<TransportSearchFiltersState, TransportSearchFiltersState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                TransportSearchFiltersState,
                TransportSearchFiltersState
              >,
              TransportSearchFiltersState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
