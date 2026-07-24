import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../tracking/presentation/state/driver_tracking_state.dart';

/// Overlay flutuante no topo do mapa de rotas.
///
/// Exibe o status de conexão, velocidade atual e o botão de finalizar rota.
class RouteTopOverlay extends StatelessWidget {
  const RouteTopOverlay({
    super.key,
    required this.tracking,
    required this.isFinishing,
    this.onFinish,
  });

  final DriverTrackingState tracking;
  final bool isFinishing;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ConnectionPill(tracking: tracking),
        const Spacer(),
        if (tracking.lastSpeedKmh != null) ...[
          _SpeedChip(speedKmh: tracking.lastSpeedKmh!),
          const SizedBox(width: 8),
        ],
        if (tracking.routeActive)
          _FinishBtn(onTap: onFinish, loading: isFinishing),
      ],
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({required this.tracking});
  final DriverTrackingState tracking;

  (Color, String) get _state {
    if (!tracking.routeActive) return (AppColors.muted, 'Aguardando');
    if (tracking.foregroundStreaming && tracking.socketConnected) {
      return (AppColors.success, 'Ao vivo');
    }
    if (tracking.foregroundStreaming) {
      return (AppColors.warning, 'GPS ativo');
    }
    return (AppColors.warning, 'Fallback');
  }

  @override
  Widget build(BuildContext context) {
    final (color, label) = _state;
    return _MapPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({required this.speedKmh});
  final int speedKmh;

  @override
  Widget build(BuildContext context) {
    return _MapPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.speed_rounded, size: 13, color: AppColors.ink),
          const SizedBox(width: 5),
          Text(
            '$speedKmh km/h',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinishBtn extends StatelessWidget {
  const _FinishBtn({this.onTap, this.loading = false});
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: (loading ? AppColors.muted : AppColors.danger).withValues(
        alpha: 0.93,
      ),
      borderRadius: BorderRadius.circular(AppRadius.full),
      elevation: 0,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(Icons.stop_rounded, size: 13, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  loading ? 'Finalizando...' : 'Finalizar',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapPill extends StatelessWidget {
  const _MapPill({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
