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
  });

  final ParentRealtimeStatus status;
  final int? routeId;
  final double? latitude;
  final double? longitude;

  /// Momento da última posição recebida via socket.
  final DateTime? updatedAt;

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
    bool clearPosition = false,
  }) {
    return ParentRealtimeState(
      status: status ?? this.status,
      routeId: routeId ?? this.routeId,
      latitude: clearPosition ? null : (latitude ?? this.latitude),
      longitude: clearPosition ? null : (longitude ?? this.longitude),
      updatedAt: clearPosition ? null : (updatedAt ?? this.updatedAt),
    );
  }
}

/// Controla o ciclo de vida do socket do pai: assina a rota ativa, reflete
/// as posições recebidas no estado e encerra tudo quando a tela sai (o
/// provider é autoDispose).
class ParentRealtimeController extends Notifier<ParentRealtimeState> {
  late final ParentRealtimeService _service;
  StreamSubscription<ParentVanLocation>? _locationSub;
  StreamSubscription<ParentRealtimeStatus>? _statusSub;

  @override
  ParentRealtimeState build() {
    _service = ref.watch(parentRealtimeServiceProvider);
    _locationSub = _service.locations.listen(_onLocation);
    _statusSub = _service.statusChanges.listen(_onStatus);
    ref.onDispose(() {
      _locationSub?.cancel();
      _statusSub?.cancel();
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
  }

  /// Encerra a assinatura (rota finalizada/sem rota ativa).
  void unwatch() {
    _service.unwatch();
    if (!ref.mounted) return;
    state = const ParentRealtimeState();
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
  }
}
