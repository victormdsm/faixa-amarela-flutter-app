import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../domain/ad.dart';

/// Papel da audiência da sessão atual: visitante veicula como `public`,
/// sessão aberta veicula pelo portal em que entrou. Alimenta a segmentação
/// por público do feed e a dimensão `audience_role` das métricas.
///
/// Fica fora de `ads_providers.dart` porque o controller de sessão importa
/// aquele arquivo para invalidar o feed — a dependência inversa fecharia um
/// ciclo entre os dois.
final adAudienceRoleProvider = Provider<AdRole>((ref) {
  final state = ref.watch(appSessionControllerProvider);
  if (state.session == null) return AdRole.public;
  return switch (state.loginRole) {
    UserRole.driver => AdRole.driver,
    UserRole.parent => AdRole.parent,
    null => AdRole.public,
  };
});
