import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/parent_realtime_service.dart';
import '../providers/parent_portal_providers.dart';

/// Estado do acompanhamento em tempo real da van (socket do app do pai).
class ParentRealtimeState {
  const ParentRealtimeState({
    this.status = ParentRealtimeStatus.disconnected,
    this.routeId,
    this.latitude,
    this.longitude,
    this.updatedAt,
    this.connectionIssue = false,
  });

  final ParentRealtimeStatus status;
  final int? routeId;
  final double? latitude;
  final double? longitude;

  /// Momento da última posição recebida via socket.
  final DateTime? updatedAt;

  /// Sem conexão em tempo real de forma persistente (ver
  /// [ParentRealtimeController.outageGracePeriod]). Antes disso a queda é
  /// tratada como transitória — o polling HTTP de 15s cobre sem alarme.
  final bool connectionIssue;

  /// Socket conectado e assinado na rota: marcador atualiza em tempo real e
  /// o polling HTTP fica em standby (fallback).
  bool get isLive => status == ParentRealtimeStatus.connected;

  LatLng? get position {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  ParentRealtimeState copyWith({
    ParentRealtimeStatus? status,
    int? routeId,
    double? latitude,
    double? longitude,
    DateTime? updatedAt,
    bool? connectionIssue,
    bool clearPosition = false,
  }) {
    return ParentRealtimeState(
      status: status ?? this.status,
      routeId: routeId ?? this.routeId,
      latitude: clearPosition ? null : (latitude ?? this.latitude),
      longitude: clearPosition ? null : (longitude ?? this.longitude),
      updatedAt: clearPosition ? null : (updatedAt ?? this.updatedAt),
      connectionIssue: connectionIssue ?? this.connectionIssue,
    );
  }
}

/// Controla o ciclo de vida do socket do pai: assina a rota ativa, reflete
/// as posições recebidas no estado e encerra tudo quando a tela sai (o
/// provider é autoDispose).
///
/// Quedas de conexão são normais em rede móvel e o socket se reconecta
/// sozinho — por isso o estado só vira "problema" (`connectionIssue`)
/// depois de [outageGracePeriod] sem conectar. Até lá a UI mostra um
/// estado neutro de atualização e o polling HTTP cobre.
class ParentRealtimeController extends Notifier<ParentRealtimeState> {
  /// Tempo sem conexão em tempo real a partir do qual a UI passa a exibir o
  /// estado de problema persistente (com ação de tentar de novo).
  static const outageGracePeriod = Duration(seconds: 30);

  late final ParentRealtimeService _service;
  StreamSubscription<ParentVanLocation>? _locationSub;
  StreamSubscription<ParentRealtimeStatus>? _statusSub;
  StreamSubscription<ParentRouteStatusEvent>? _routeStatusSub;
  StreamSubscription<ParentBoardingStatusEvent>? _boardingStatusSub;
  Timer? _outageTimer;

  @override
  ParentRealtimeState build() {
    _service = ref.watch(parentRealtimeServiceProvider);
    _locationSub = _service.locations.listen(_onLocation);
    _statusSub = _service.statusChanges.listen(_onStatus);
    _routeStatusSub = _service.routeStatuses.listen(_onRouteStatus);
    _boardingStatusSub = _service.boardingStatuses.listen(_onBoardingStatus);
    ref.onDispose(() {
      _outageTimer?.cancel();
      _locationSub?.cancel();
      _statusSub?.cancel();
      _routeStatusSub?.cancel();
      _boardingStatusSub?.cancel();
      _service.unwatch();
    });
    return const ParentRealtimeState();
  }

  /// Assina a rota [routeId] no socket. Idempotente: chamadas repetidas com
  /// a mesma rota viva não reabrem conexão nem ressubscrevem.
  void watchRoute({required int routeId, required String token}) {
    if (state.routeId == routeId &&
        _service.watchedRouteId == routeId &&
        state.status != ParentRealtimeStatus.disconnected) {
      return;
    }
    // Troca de rota: posição anterior não vale mais.
    state = ParentRealtimeState(status: _service.status, routeId: routeId);
    _service.watchRoute(routeId: routeId, token: token);
    _syncOutageTimer();
  }

  /// Encerra a assinatura (rota finalizada/sem rota ativa).
  void unwatch() {
    _outageTimer?.cancel();
    _outageTimer = null;
    _service.unwatch();
    if (!ref.mounted) return;
    state = const ParentRealtimeState();
  }

  /// Ação "tentar de novo" do estado de falha persistente: descarta o socket
  /// travado e abre uma conexão nova (a reconexão automática continua valendo
  /// para quedas futuras).
  void retry() {
    if (state.routeId == null) return;
    _service.reconnect();
    if (!ref.mounted) return;
    state = state.copyWith(
      status: _service.status,
      connectionIssue: false,
    );
    _syncOutageTimer();
  }

  void _onLocation(ParentVanLocation location) {
    if (!ref.mounted) return;
    final watched = state.routeId;
    if (watched != null &&
        location.routeId != null &&
        location.routeId != watched) {
      return;
    }
    state = state.copyWith(
      latitude: location.latitude,
      longitude: location.longitude,
      updatedAt: location.at ?? DateTime.now(),
    );
  }

  void _onStatus(ParentRealtimeStatus status) {
    if (!ref.mounted) return;
    state = state.copyWith(status: status);
    _syncOutageTimer();
  }

  /// Início/fim de rota chega por socket: a lista HTTP segue sendo a fonte
  /// de verdade da tela, mas é revalidada na hora em vez de esperar o
  /// polling de fallback (que fica em standby com o socket vivo).
  void _onRouteStatus(ParentRouteStatusEvent event) {
    if (!ref.mounted) return;
    ref.invalidate(parentRoutesProvider);
    ref.invalidate(parentChildrenProvider);
  }

  /// Embarque/desembarque muda o manifesto exibido no overlay — revalida as
  /// rotas para refletir o status novo sem depender do polling.
  void _onBoardingStatus(ParentBoardingStatusEvent event) {
    if (!ref.mounted) return;
    ref.invalidate(parentRoutesProvider);
  }

  /// Liga o timer de falha persistente enquanto há rota assinada sem
  /// conexão; cancela (e limpa a flag) assim que o socket volta.
  void _syncOutageTimer() {
    final waitingConnection = state.routeId != null && !state.isLive;
    if (waitingConnection) {
      _outageTimer ??= Timer(outageGracePeriod, _onOutageGracePeriodEnded);
    } else {
      _outageTimer?.cancel();
      _outageTimer = null;
      if (state.connectionIssue) {
        state = state.copyWith(connectionIssue: false);
      }
    }
  }

  void _onOutageGracePeriodEnded() {
    _outageTimer = null;
    if (!ref.mounted) return;
    if (state.routeId == null || state.isLive) return;
    state = state.copyWith(connectionIssue: true);
  }
}
