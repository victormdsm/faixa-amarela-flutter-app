import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_theme.dart';

/// Mapa do card de endereço (add_child_page): plota o marcador na posição
/// geocodificada e permite ao pai ARRASTAR o marcador para ajuste fino.
///
/// O widget é controlado: [position] vem do pai (geocode ou gesto anterior)
/// e cada movimento do marcador é devolvido via [onChanged].
class AddressMapPicker extends StatefulWidget {
  const AddressMapPicker({
    super.key,
    required this.position,
    required this.onChanged,
  });

  final LatLng position;
  final ValueChanged<LatLng> onChanged;

  @override
  State<AddressMapPicker> createState() => _AddressMapPickerState();
}

class _AddressMapPickerState extends State<AddressMapPicker> {
  final _mapController = MapController();
  bool _mapReady = false;
  bool _dragging = false;

  @override
  void didUpdateWidget(covariant AddressMapPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Um novo geocode recentraliza o mapa; durante o arraste a posição vem
    // do próprio gesto, então a câmera não é movida (evita loop/jitter).
    if (!_dragging && _mapReady && oldWidget.position != widget.position) {
      _mapController.move(widget.position, _mapController.camera.zoom);
    }
  }

  void _onMarkerPointerMove(PointerMoveEvent event) {
    if (!_dragging || !_mapReady) return;
    final camera = _mapController.camera;
    final screenPoint =
        camera.latLngToScreenOffset(widget.position) + event.delta;
    widget.onChanged(camera.screenOffsetToLatLng(screenPoint));
  }

  @override
  Widget build(BuildContext context) {
    // Enquanto o marcador está sendo arrastado, o pan do mapa é desligado
    // para o gesto não mover o mapa junto.
    final flags = _dragging
        ? InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom
        : InteractiveFlag.drag |
            InteractiveFlag.pinchZoom |
            InteractiveFlag.doubleTapZoom;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.position,
            initialZoom: 16,
            onMapReady: () => _mapReady = true,
            interactionOptions: InteractionOptions(flags: flags),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'br.com.faixaamarela.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: widget.position,
                  width: 48,
                  height: 48,
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) => setState(() => _dragging = true),
                    onPointerMove: _onMarkerPointerMove,
                    onPointerUp: (_) => setState(() => _dragging = false),
                    onPointerCancel: (_) => setState(() => _dragging = false),
                    child: const _AddressPinMarker(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Marcador do endereço no padrão da marca: círculo amarelo com borda ink e
/// o glyph de localização, como o marcador da van no mapa de tracking.
class _AddressPinMarker extends StatelessWidget {
  const _AddressPinMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.yellow,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.location_on_rounded,
        color: AppColors.ink,
        size: 26,
      ),
    );
  }
}
