import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ads_repository.dart';
import '../../domain/ad.dart';

/// Chave de consulta de anúncios por superfície.
typedef AdQuery = ({String placement, AdRole role});

/// Anúncios de um placement. `keepAlive`: cache leve em memória por
/// placement (são poucos slots fixos), invalidado no pull-to-refresh das
/// páginas e no retorno do app ao foreground.
final adsProvider = FutureProvider.family<List<Ad>, AdQuery>((
  ref,
  query,
) async {
  ref.keepAlive();
  return ref
      .watch(adsRepositoryProvider)
      .fetchAds(placement: query.placement, role: query.role);
});
