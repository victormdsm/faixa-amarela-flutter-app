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

  primeTrackingStopsFromManifest(ref, manifest);
}

/// Retoma o rastreamento de uma rota que o backend ainda considera ativa.
///
/// O estado do [DriverTrackingController] vive só em memória: fechar o app
/// (ou qualquer recriação do notifier) zerava `routeActive` enquanto a rota
/// seguia ativa no backend — a tela do mapa voltava vazia e não havia como
/// recuperar a visualização. Aqui o backend é a fonte de verdade: dado o
/// manifesto de `/driver/routes/active`, o rastreamento é religado com os
/// mesmos identificadores e as paradas são repopuladas na hora, sem esperar
/// o primeiro recálculo por GPS.
///
/// Retorna `true` quando o rastreamento voltou a ficar ativo.
Future<bool> resumeTrackingFromManifest(
  WidgetRef ref,
  RouteManifest manifest,
) async {
  final session = ref.read(appSessionControllerProvider).session;
  if (session == null) return false;

  final routeId = manifest.id;
  final manifestId = manifest.manifestId ?? '';
  if (routeId <= 0 || manifestId.isEmpty || manifest.vanId <= 0) return false;

  final ctrl = ref.read(driverTrackingControllerProvider.notifier);
  final resumed = await ctrl.startRouteTracking(
    session: session,
    routeId: routeId,
    routeManifestId: manifestId,
    vanId: manifest.vanId,
  );
  if (!resumed) return false;

  primeTrackingStopsFromManifest(ref, manifest);
  return true;
}

/// Popula as paradas do tracking a partir do manifesto do backend.
///
/// `startRouteTracking` limpa o preview da rota; sem isto a lista de alunos
/// só aparece depois do primeiro `/recalculate`, que depende de um fix de
/// GPS e pode demorar. As paradas do manifesto já trazem coordenadas.
void primeTrackingStopsFromManifest(WidgetRef ref, RouteManifest manifest) {
  final stops = manifest.stops
      .where((stop) => stop.latitude != null && stop.longitude != null)
      .map(
        (stop) => <String, dynamic>{
          if (stop.id != null) 'id': stop.id,
          'childId': stop.childId,
          'type': stop.type ?? 'pickup',
          'status': stop.status.toJson(),
          'sequence': stop.sequence,
          'latitude': stop.latitude,
          'longitude': stop.longitude,
          'name': stop.childName,
        },
      )
      .toList(growable: false);

  if (stops.isEmpty) return;
  ref
      .read(driverTrackingControllerProvider.notifier)
      .primeRoutePreview(remainingStops: stops);
}
