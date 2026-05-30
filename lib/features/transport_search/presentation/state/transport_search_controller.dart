import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/service_period.dart';
import 'transport_search_filters_state.dart';

part 'transport_search_controller.g.dart';

@riverpod
class TransportSearchController extends _$TransportSearchController {
  @override
  TransportSearchFiltersState build() {
    return const TransportSearchFiltersState();
  }

  void setSchool(String? school) {
    state = state.copyWith(school: school, neighborhood: null);
  }

  void setNeighborhood(String? neighborhood) {
    state = state.copyWith(neighborhood: neighborhood);
  }

  void setPeriod(ServicePeriod? period) {
    state = state.copyWith(period: period);
  }

  void clearAll() {
    state = const TransportSearchFiltersState();
  }
}
