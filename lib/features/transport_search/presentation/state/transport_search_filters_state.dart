import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/service_period.dart';

part 'transport_search_filters_state.freezed.dart';

@freezed
abstract class TransportSearchFiltersState with _$TransportSearchFiltersState {
  const TransportSearchFiltersState._();

  const factory TransportSearchFiltersState({
    String? school,
    String? neighborhood,
    ServicePeriod? period,
  }) = _TransportSearchFiltersState;

  bool get canSearch =>
      school != null && neighborhood != null && period != null;
}
