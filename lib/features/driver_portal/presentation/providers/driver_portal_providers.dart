import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/network_providers.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../data/driver_portal_repository.dart';

final driverPortalRepositoryProvider = Provider<DriverPortalRepository>(
  (ref) => DriverPortalRepository(ref.watch(dioProvider)),
);

String _requireDriverAuthHeader(Ref ref) {
  final session = ref.watch(appSessionControllerProvider).session;
  if (session == null) {
    throw ApiException(message: 'Sessao expirada. Faca login novamente.');
  }
  return session.authorizationHeader;
}

final driverClientsProvider = FutureProvider.autoDispose((ref) async {
  final auth = _requireDriverAuthHeader(ref);
  return ref.watch(driverPortalRepositoryProvider).clients(auth);
});

final driverRoutesProvider = FutureProvider.autoDispose((ref) async {
  final auth = _requireDriverAuthHeader(ref);
  return ref.watch(driverPortalRepositoryProvider).routes(auth);
});

final driverClientChildrenProvider = FutureProvider.autoDispose.family((
  ref,
  int clientId,
) async {
  final auth = _requireDriverAuthHeader(ref);
  return ref
      .watch(driverPortalRepositoryProvider)
      .clientChildren(auth, clientId);
});

// Not autoDispose — profile and van image stay cached in memory for the session.
final driverProfileProvider = FutureProvider((ref) async {
  final auth = _requireDriverAuthHeader(ref);
  return ref.watch(driverPortalRepositoryProvider).profile(auth);
});

final driverRoutePresetsProvider = FutureProvider.autoDispose((ref) async {
  final auth = _requireDriverAuthHeader(ref);
  return ref.watch(driverPortalRepositoryProvider).listRoutePresets(auth);
});
