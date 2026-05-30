import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart' show dioProvider;
import '../../../catalog/data/catalog_repository.dart';
import '../../data/repositories/public_transport_search_repository.dart';
import '../../domain/entities/public_transport_driver.dart';
import '../../domain/entities/service_period.dart';
import '../state/transport_search_controller.dart';

final publicTransportSearchRepositoryProvider =
    Provider<PublicTransportSearchRepository>(
      (ref) => PublicTransportSearchRepository(ref.watch(dioProvider)),
    );

final availableSchoolsProvider = Provider<List<String>>((ref) {
  final options = ref.watch(schoolsCatalogProvider).value ?? const [];
  final names = options.map((e) => e.name).toSet().toList()..sort();
  return names;
});

final availableNeighborhoodsProvider = Provider<List<String>>((ref) {
  final options = ref.watch(districtsCatalogProvider).value ?? const [];
  final names = options.map((e) => e.name).toSet().toList()..sort();
  return names;
});

final _selectedSchoolIdProvider = Provider<int?>((ref) {
  final label = ref.watch(transportSearchControllerProvider).school;
  if (label == null) return null;
  final options = ref.watch(schoolsCatalogProvider).value ?? const [];
  for (final option in options) {
    if (option.name == label) return option.id;
  }
  return null;
});

final _selectedDistrictIdProvider = Provider<int?>((ref) {
  final label = ref.watch(transportSearchControllerProvider).neighborhood;
  if (label == null) return null;
  final options = ref.watch(districtsCatalogProvider).value ?? const [];
  for (final option in options) {
    if (option.name == label) return option.id;
  }
  return null;
});

final _selectedShiftIdProvider = Provider<int?>((ref) {
  final period = ref.watch(transportSearchControllerProvider).period;
  if (period == null) return null;

  final shifts = ref.watch(shiftsCatalogProvider).value ?? const [];
  final normalizedTarget = _periodKey(period);

  for (final shift in shifts) {
    final key = _normalize(shift.name);
    if (normalizedTarget == 'manha' && key.contains('manha')) return shift.id;
    if (normalizedTarget == 'tarde' && key.contains('tarde')) return shift.id;
    if (normalizedTarget == 'noite' && key.contains('noite')) return shift.id;
    if (normalizedTarget == 'integral' &&
        (key.contains('integral') || key.contains('dia todo'))) {
      return shift.id;
    }
  }

  // Fallback comum em seeds antigas (1..4).
  return switch (period) {
    ServicePeriod.morning => 1,
    ServicePeriod.afternoon => 2,
    ServicePeriod.night => 3,
    ServicePeriod.fullTime => 4,
  };
});

final transportDriversProvider = FutureProvider<List<PublicTransportDriver>>((
  ref,
) async {
  final filters = ref.watch(transportSearchControllerProvider);
  final schoolId = ref.watch(_selectedSchoolIdProvider);
  final districtId = ref.watch(_selectedDistrictIdProvider);
  final shiftId = ref.watch(_selectedShiftIdProvider);

  if (!filters.canSearch ||
      schoolId == null ||
      districtId == null ||
      shiftId == null) {
    return const [];
  }

  return ref
      .watch(publicTransportSearchRepositoryProvider)
      .search(schoolId: schoolId, districtId: districtId, shiftId: shiftId);
});

final filteredTransportDriversProvider = Provider<List<PublicTransportDriver>>((
  ref,
) {
  // A API ja retorna filtrado; mantemos este provider para a UI existente.
  return ref.watch(transportDriversProvider).value ?? const [];
});

String _periodKey(ServicePeriod period) {
  return switch (period) {
    ServicePeriod.morning => 'manha',
    ServicePeriod.afternoon => 'tarde',
    ServicePeriod.night => 'noite',
    ServicePeriod.fullTime => 'integral',
  };
}

String _normalize(String value) {
  final source = value.toLowerCase();
  const accents = {
    'a': 'a',
    'á': 'a',
    'à': 'a',
    'ã': 'a',
    'â': 'a',
    'e': 'e',
    'é': 'e',
    'ê': 'e',
    'i': 'i',
    'í': 'i',
    'o': 'o',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'u': 'u',
    'ú': 'u',
    'ç': 'c',
  };

  final buffer = StringBuffer();
  for (final rune in source.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(accents[char] ?? char);
  }
  return buffer.toString();
}
