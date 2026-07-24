import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../tracking/presentation/state/driver_tracking_state.dart';

/// Visualização do mapa com a rota ativa, paradas e localização do motorista.
///
/// Inclui controles de zoom, recentralização e um boundary básico de erro.
class RouteMapView extends StatefulWidget {
  const RouteMapView({super.key, required this.tracking});

  final DriverTrackingState tracking;

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView> {
  MapLibreMapController? _ctrl;
  bool _ready = false;
  bool _markersReady = false;
  bool _followMode = true;
  bool _hasError = false;
  Object? _error;

  static const _styleUrl = 'https://tiles.openfreemap.org/styles/liberty';
  static const _defaultCenter = LatLng(-25.5401, -54.5854);

  // Ícones de marker renderizados em 3x e exibidos com iconSize 1/3.
  static const _vanMarkerImage = 'faixa-van-marker';
  static const _stopHomeMarkerImage = 'faixa-stop-home-marker';
  static const _stopSchoolMarkerImage = 'faixa-stop-school-marker';
  static const _markerIconSize = 1 / 3;

  @override
  void didUpdateWidget(covariant RouteMapView old) {
    super.didUpdateWidget(old);
    if (_ready && !_hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncMap();
      });
    }
  }

  Future<void> _registerMarkerImages() async {
    final c = _ctrl;
    if (c == null || _markersReady) return;
    try {
      final van = await _renderMarkerImage(156, _paintVanMarker);
      final stopHome = await _renderMarkerImage(
        120,
        (canvas, size) => _paintStopMarker(canvas, size, Icons.home_rounded),
      );
      final stopSchool = await _renderMarkerImage(
        120,
        (canvas, size) => _paintStopMarker(canvas, size, Icons.school_rounded),
      );
      await _tryAddImage(c, _vanMarkerImage, van);
      await _tryAddImage(c, _stopHomeMarkerImage, stopHome);
      await _tryAddImage(c, _stopSchoolMarkerImage, stopSchool);
      _markersReady = true;
    } catch (_) {
      // Sem as imagens, _syncMap usa os círculos anteriores como fallback.
      _markersReady = false;
    }
  }

  Future<void> _tryAddImage(
    MapLibreMapController c,
    String name,
    Uint8List bytes,
  ) async {
    try {
      await c.addImage(name, bytes);
    } catch (_) {
      // Imagem já registrada no estilo atual (ex.: hot reload) — ignora.
    }
  }

  Future<void> _syncMap() async {
    final c = _ctrl;
    if (c == null || !_ready) return;
    try {
      await c.clearLines();
      await c.clearCircles();
      await c.clearSymbols();

      final t = widget.tracking;
      final current = (t.lastLatitude != null && t.lastLongitude != null)
          ? LatLng(t.lastLatitude!, t.lastLongitude!)
          : null;
      final poly = t.routePolyline.map((p) => LatLng(p.lat, p.lng)).toList();
      final stops = t.routeRemainingStops;
      final fallback = [?current, ...stops.map((s) => LatLng(s.lat, s.lng))];
      final display = poly.length >= 2 ? poly : fallback;
      final usingApprox = poly.length < 2 && fallback.length >= 2;

      if (display.length >= 2) {
        await c.addLine(
          LineOptions(
            geometry: display,
            lineColor: '#1A1614',
            lineWidth: 8.0,
            lineOpacity: 0.14,
            lineJoin: 'round',
          ),
        );
        await c.addLine(
          LineOptions(
            geometry: display,
            lineColor: usingApprox ? '#64B5F6' : '#FF9E1B',
            lineWidth: 4.5,
            lineOpacity: 1.0,
            lineJoin: 'round',
          ),
        );
      }

      for (final s in stops) {
        final point = LatLng(s.lat, s.lng);
        if (_markersReady) {
          await c.addSymbol(
            SymbolOptions(
              geometry: point,
              iconImage: _stopMarkerImageFor(s.type),
              iconSize: _markerIconSize,
            ),
          );
        } else {
          await c.addCircle(
            CircleOptions(
              geometry: point,
              circleRadius: 9.0,
              circleColor: '#FFFFFF',
              circleStrokeColor: '#E05252',
              circleStrokeWidth: 2.5,
            ),
          );
        }
      }

      if (current != null) {
        await c.addCircle(
          CircleOptions(
            geometry: current,
            circleRadius: 20.0,
            circleColor: '#FF9E1B',
            circleOpacity: 0.22,
            circleStrokeWidth: 0,
          ),
        );
        if (_markersReady) {
          await c.addSymbol(
            SymbolOptions(
              geometry: current,
              iconImage: _vanMarkerImage,
              iconSize: _markerIconSize,
            ),
          );
        } else {
          await c.addCircle(
            CircleOptions(
              geometry: current,
              circleRadius: 12.0,
              circleColor: '#FF9E1B',
              circleStrokeColor: '#1A1614',
              circleStrokeWidth: 2.5,
            ),
          );
        }
      }

      if (_followMode) _animateToDriver();
    } catch (e) {
      if (mounted && !_hasError) {
        setState(() {
          _hasError = true;
          _error = e;
        });
      }
    }
  }

  void _animateToDriver() {
    final c = _ctrl;
    if (c == null || !_ready) return;
    final t = widget.tracking;
    if (t.lastLatitude != null && t.lastLongitude != null) {
      c.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(t.lastLatitude!, t.lastLongitude!),
          15.5,
        ),
      );
    }
  }

  void _recenter() {
    final c = _ctrl;
    if (c == null || !_ready) return;
    final t = widget.tracking;
    final current = (t.lastLatitude != null && t.lastLongitude != null)
        ? LatLng(t.lastLatitude!, t.lastLongitude!)
        : null;
    final poly = t.routePolyline.map((p) => LatLng(p.lat, p.lng)).toList();
    final stops = t.routeRemainingStops
        .map((s) => LatLng(s.lat, s.lng))
        .toList();
    final all = [?current, ...poly, ...stops];
    final center = _avgLatLng(all) ?? current ?? _defaultCenter;
    final zoom = poly.length >= 2 ? 13.4 : 16.2;
    c.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: center, zoom: zoom),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return _placeholder(context, _error);

    final t = widget.tracking;
    final current = (t.lastLatitude != null && t.lastLongitude != null)
        ? LatLng(t.lastLatitude!, t.lastLongitude!)
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep buttons above the sheet's initial snap position (30% active / 20% idle)
        final buttonBottom =
            constraints.maxHeight * (t.routeActive ? 0.36 : 0.26) + 8;

        return Stack(
          children: [
            MapLibreMap(
              styleString: _styleUrl,
              initialCameraPosition: CameraPosition(
                target: current ?? _defaultCenter,
                zoom: 14.0,
              ),
              onMapCreated: (c) => _ctrl = c,
              onStyleLoadedCallback: () async {
                await _registerMarkerImages();
                if (!mounted) return;
                setState(() => _ready = true);
                _syncMap();
              },
              compassEnabled: false,
              myLocationEnabled: false,
              tiltGesturesEnabled: false,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: false,
              onMapClick: (_, _) {
                if (_followMode) setState(() => _followMode = false);
              },
            ),

            // Map controls (right side, dynamically above bottom sheet)
            Positioned(
              right: 12,
              bottom: buttonBottom,
              child: Column(
                children: [
                  _MapBtn(
                    icon: Icons.add_rounded,
                    onPressed: !_ready
                        ? null
                        : () => _ctrl?.animateCamera(CameraUpdate.zoomIn()),
                  ),
                  const SizedBox(height: 6),
                  _MapBtn(
                    icon: Icons.remove_rounded,
                    onPressed: !_ready
                        ? null
                        : () => _ctrl?.animateCamera(CameraUpdate.zoomOut()),
                  ),
                  const SizedBox(height: 6),
                  _MapBtn(
                    icon: _followMode
                        ? Icons.my_location_rounded
                        : Icons.location_searching_rounded,
                    active: _followMode,
                    onPressed: !_ready
                        ? null
                        : () {
                            setState(() => _followMode = true);
                            _animateToDriver();
                          },
                  ),
                  const SizedBox(height: 6),
                  _MapBtn(
                    icon: Icons.fit_screen_rounded,
                    onPressed: !_ready ? null : _recenter,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _placeholder(BuildContext context, [Object? error]) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(Icons.map_outlined, size: 28, color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Mapa indisponivel',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.slate,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                '$error',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapBtn extends StatelessWidget {
  const _MapBtn({
    required this.icon,
    required this.onPressed,
    this.active = false,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? AppColors.yellow.withValues(alpha: 0.9)
          : AppColors.surface.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(AppRadius.md),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: AppColors.ink, size: 22),
        ),
      ),
    );
  }
}

LatLng? _avgLatLng(List<LatLng> pts) {
  if (pts.isEmpty) return null;
  var lat = 0.0, lng = 0.0;
  for (final p in pts) {
    lat += p.latitude;
    lng += p.longitude;
  }
  return LatLng(lat / pts.length, lng / pts.length);
}

/// Escolhe o ícone da parada: `school` para paradas de escola e `home` para
/// residências (tipos pickup/dropoff sem sufixo caem em `home`).
String _stopMarkerImageFor(String? type) {
  final t = (type ?? '').toLowerCase();
  if (t.contains('school')) {
    return _RouteMapViewState._stopSchoolMarkerImage;
  }
  return _RouteMapViewState._stopHomeMarkerImage;
}

typedef _MarkerPainter = void Function(Canvas canvas, Size size);

/// Rasteriza um marker customizado para uso como ícone de símbolo no MapLibre.
Future<Uint8List> _renderMarkerImage(
  double size,
  _MarkerPainter painter,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  painter(canvas, Size.square(size));
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(size.toInt(), size.toInt());
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw StateError('Falha ao rasterizar marker do mapa.');
      }
      return bytes.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

/// Marcador da van, espelhando o `_VanMarker` do mapa do responsável:
/// círculo amarelo #FF9E1B, faixa ink diagonal na base e ônibus ink.
/// Medidas em "px lógicos" de 52 (renderizado em 3x = 156).
void _paintVanMarker(Canvas canvas, Size size) {
  const ink = Color(0xFF1B1C1A);
  const yellow = Color(0xFFFF9E1B);
  final s = size.width / 52;
  final center = size.center(Offset.zero);
  final radius = 26 * s;
  final borderWidth = 2.5 * s;

  canvas.drawCircle(center, radius - borderWidth / 2, Paint()..color = yellow);

  // Faixa ink levemente diagonal na base, clipada ao círculo interno.
  canvas.save();
  canvas.clipPath(
    Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius - borderWidth)),
  );
  canvas.translate(center.dx, center.dy + 18 * s);
  canvas.rotate(-0.14);
  canvas.drawRect(
    Rect.fromCenter(center: Offset.zero, width: 64 * s, height: 12 * s),
    Paint()..color = ink,
  );
  canvas.restore();

  canvas.drawCircle(
    center,
    radius - borderWidth / 2,
    Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth,
  );

  _drawIconGlyph(
    canvas,
    icon: Icons.directions_bus_rounded,
    color: ink,
    fontSize: 24 * s,
    center: Offset(center.dx, center.dy - 4 * s),
  );
}

/// Pin de parada: círculo ink com borda branca e glyph branco (escola/casa).
/// Medidas em "px lógicos" de 40 (renderizado em 3x = 120).
void _paintStopMarker(Canvas canvas, Size size, IconData icon) {
  const ink = Color(0xFF1B1C1A);
  final s = size.width / 40;
  final center = size.center(Offset.zero);
  final radius = 20 * s;
  final borderWidth = 2.5 * s;

  canvas.drawCircle(center, radius - borderWidth / 2, Paint()..color = ink);
  canvas.drawCircle(
    center,
    radius - borderWidth / 2,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth,
  );

  _drawIconGlyph(
    canvas,
    icon: icon,
    color: Colors.white,
    fontSize: 20 * s,
    center: center,
  );
}

void _drawIconGlyph(
  Canvas canvas, {
  required IconData icon,
  required Color color,
  required double fontSize,
  required Offset center,
}) {
  final textPainter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        inherit: false,
        color: color,
        fontSize: fontSize,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  textPainter.paint(
    canvas,
    center - Offset(textPainter.width / 2, textPainter.height / 2),
  );
}
