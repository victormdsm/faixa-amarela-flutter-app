import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_theme.dart';

/// Mapa full-screen com a localização atual do motorista e a(s) escola(s)
/// da rota (âncora da viagem).
class DriverLocationMap extends StatelessWidget {
  const DriverLocationMap({super.key, this.driverPos, this.schoolPoints = const []});

  final LatLng? driverPos;

  /// Coordenadas das escolas da rota (stops type "school" do manifesto).
  final List<LatLng> schoolPoints;

  @override
  Widget build(BuildContext context) {
    final center = driverPos ??
        (schoolPoints.isNotEmpty ? schoolPoints.first : null) ??
        const LatLng(-25.5401, -54.5854);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: driverPos != null ? 15.0 : 13.0,
        interactionOptions: const InteractionOptions(
          flags:
              InteractiveFlag.drag |
              InteractiveFlag.pinchZoom |
              InteractiveFlag.doubleTapZoom,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'br.com.faixaamarela.app',
        ),
        if (schoolPoints.isNotEmpty)
          MarkerLayer(
            markers: [
              for (final point in schoolPoints)
                Marker(
                  point: point,
                  width: 44,
                  height: 44,
                  child: const _SchoolMarker(),
                ),
            ],
          ),
        if (driverPos != null)
          MarkerLayer(
            markers: [
              Marker(
                point: driverPos!,
                width: 52,
                height: 52,
                child: const _VanMarker(),
              ),
            ],
          ),
      ],
    );
  }
}

/// Marcador da escola: pin ink com borda branca e glyph de escola — distinto
/// da van (amarela), seguindo o padrão dos pins de parada do mapa do motorista.
class _SchoolMarker extends StatelessWidget {
  const _SchoolMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.ink,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.school_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

/// Marcador da van no padrão da marca: círculo amarelo `#FF9E1B` com a faixa
/// (listra) ink estilo sinalização na base e o glyph do ônibus em ink.
class _VanMarker extends StatelessWidget {
  const _VanMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.yellow,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Faixa ink levemente diagonal, como na sinalização escolar.
            Align(
              alignment: const Alignment(0, 0.78),
              child: Transform.rotate(
                angle: -0.14,
                child: Container(
                  width: 64,
                  height: 12,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Icon(
                  Icons.directions_bus_rounded,
                  color: AppColors.ink,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
