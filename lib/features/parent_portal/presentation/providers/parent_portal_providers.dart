import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/network_providers.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../data/parent_portal_repository.dart';

final parentPortalRepositoryProvider = Provider<ParentPortalRepository>(
  (ref) => ParentPortalRepository(ref.watch(dioProvider)),
);

String _requireParentAuthHeader(Ref ref) {
  final session = ref.watch(appSessionControllerProvider).session;
  if (session == null) {
    throw ApiException(message: 'Sessao expirada. Faca login novamente.');
  }
  return session.authorizationHeader;
}

final parentChildrenProvider = FutureProvider.autoDispose((ref) async {
  final auth = _requireParentAuthHeader(ref);
  return ref.watch(parentPortalRepositoryProvider).children(auth);
});

final parentRoutesProvider = FutureProvider.autoDispose((ref) async {
  final auth = _requireParentAuthHeader(ref);
  return ref.watch(parentPortalRepositoryProvider).routes(auth);
});

final parentBoardingsProvider = FutureProvider.autoDispose((ref) async {
  final auth = _requireParentAuthHeader(ref);
  return ref.watch(parentPortalRepositoryProvider).boardings(auth);
});
