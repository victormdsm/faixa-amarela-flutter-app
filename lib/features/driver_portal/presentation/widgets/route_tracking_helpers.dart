import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../domain/models/route_manifest.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../../tracking/presentation/providers/tracking_providers.dart';

/// Inicia o rastreamento a partir da resposta do backend.
Future<void> startTrackingFromResponse(
  BuildContext context,
  WidgetRef ref,
  RouteManifest manifest, {
  int? fallbackRouteId,
}) async {
  final session = ref.read(appSessionControllerProvider).session;
  if (session == null) throw ApiException(message: 'Sessão expirada.');

  final routeId = manifest.id > 0 ? manifest.id : fallbackRouteId ?? 0;
  final manifestId = manifest.manifestId ?? '';
  final vanId = manifest.vanId;

  if (routeId <= 0 || manifestId.isEmpty) {
    throw ApiException(
      message: 'Backend não retornou dados suficientes para iniciar.',
    );
  }
  if (vanId <= 0) {
    throw ApiException(message: 'Van ID invalido retornado pelo backend.');
  }

  final ctrl = ref.read(driverTrackingControllerProvider.notifier);
  final started = await ctrl.startRouteTracking(
    session: session,
    routeId: routeId,
    routeManifestId: manifestId,
    vanId: vanId,
  );
  if (!started) {
    throw ApiException(
      message:
          'Não foi possível iniciar o rastreamento. Verifique as permissões do aparelho.',
    );
  }

  // O preview da rota sera preenchido pelo primeiro recalculo de tracking.
}
