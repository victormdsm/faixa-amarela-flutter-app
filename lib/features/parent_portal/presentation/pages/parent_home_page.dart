import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/catalog_option.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../../catalog/data/catalog_repository.dart';
import '../providers/parent_portal_providers.dart';

class ParentHomePage extends ConsumerWidget {
  const ParentHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionControllerProvider).session;
    final userName = session?.user.name ?? 'Pais';

    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.login);
      });
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Area dos Pais'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Dependentes'),
              Tab(text: 'Rotas'),
              Tab(text: 'Embarques'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              onPressed: () {
                ref.invalidate(parentChildrenProvider);
                ref.invalidate(parentRoutesProvider);
                ref.invalidate(parentBoardingsProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'Sair',
              onPressed: () =>
                  ref.read(appSessionControllerProvider.notifier).clear(),
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE9E3CF)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFFFF1BE),
                    child: Icon(
                      Icons.family_restroom_rounded,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bem-vindo(a), $userName',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _ParentChildrenTab(),
                  _ParentRoutesTab(),
                  _ParentBoardingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentChildrenTab extends ConsumerWidget {
  const _ParentChildrenTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(parentChildrenProvider);
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorPane(message: error.toString()),
      data: (page) {
        final items = page.items;
        if (page.items.isEmpty) {
          return _ParentChildrenPanel(
            items: items,
            onRefresh: () => ref.invalidate(parentChildrenProvider),
          );
        }
        return _ParentChildrenPanel(
          items: items,
          onRefresh: () => ref.invalidate(parentChildrenProvider),
        );
      },
    );
  }
}

class _ParentChildrenPanel extends ConsumerWidget {
  const _ParentChildrenPanel({required this.items, required this.onRefresh});

  final List<Map<String, dynamic>> items;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Dependentes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openDependentForm(context, ref),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Adicionar'),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const _EmptyPane(message: 'Nenhum dependente encontrado.')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final name = (item['name'] ?? 'Sem nome').toString();
                    final school = (item['school'] as Map?)?['name']
                        ?.toString();
                    final relative =
                        ((item['relative'] as Map?)?['name'] ??
                                (item['relative'] as Map?)?['relative'])
                            ?.toString();
                    final shift =
                        ((item['shift'] as Map?)?['shift_name'] ??
                                (item['shift'] as Map?)?['name'])
                            ?.toString();
                    final isInadimplent = item['is_inadimplent'] == true;
                    final avatarUrl = (item['avatar_url'] ?? item['avatar'])
                        ?.toString();

                    return _InfoCard(
                      title: name,
                      subtitle: [
                        if (school != null && school.isNotEmpty)
                          'Escola: $school',
                        if (relative != null && relative.isNotEmpty)
                          'Parentesco: $relative',
                        if (shift != null && shift.isNotEmpty) 'Turno: $shift',
                        if (isInadimplent) 'Inadimplente',
                      ].join(' • '),
                      icon: Icons.family_restroom_rounded,
                      leading: _DependentAvatar(
                        avatarUrl: avatarUrl,
                        name: name,
                      ),
                      footer: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _openDependentForm(
                                context,
                                ref,
                                current: item,
                              ),
                              icon: const Icon(Icons.edit_rounded),
                              label: const Text('Editar'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmDeleteDependent(
                                context,
                                ref,
                                item,
                                onRefresh,
                              ),
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Excluir'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteDependent(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
    VoidCallback onRefresh,
  ) async {
    final id = (item['id'] as num?)?.toInt() ?? 0;
    if (id <= 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir dependente'),
        content: Text(
          'Deseja remover ${(item['name'] ?? 'este dependente').toString()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) return;
    try {
      await ref
          .read(parentPortalRepositoryProvider)
          .deleteDependent(session.authorizationHeader, id);
      onRefresh();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dependente removido com sucesso.')),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openDependentForm(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? current,
  }) async {
    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DependentFormDialog(
        current: current,
        onSubmit: (draft) async {
          final repo = ref.read(parentPortalRepositoryProvider);
          if (current == null) {
            await repo.createDependent(
              session.authorizationHeader,
              name: draft.name,
              relativeId: draft.relativeId,
              schoolId: draft.schoolId,
              shiftId: draft.shiftId,
              sex: draft.sex,
              age: draft.age,
              avatarImagePath: draft.avatarImagePath,
            );
          } else {
            final id = (current['id'] as num?)?.toInt() ?? 0;
            await repo.updateDependent(
              session.authorizationHeader,
              id,
              name: draft.name,
              relativeId: draft.relativeId,
              schoolId: draft.schoolId,
              shiftId: draft.shiftId,
              sex: draft.sex,
              age: draft.age,
              avatarImagePath: draft.avatarImagePath,
            );
          }
        },
      ),
    );

    if (result == true) {
      onRefresh();
    }
  }
}

class _ParentRoutesTab extends ConsumerWidget {
  const _ParentRoutesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(parentRoutesProvider);
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorPane(message: error.toString()),
      data: (page) {
        if (page.items.isEmpty) {
          return const _EmptyPane(message: 'Nenhuma rota encontrada.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: page.items.length,
          separatorBuilder: (_, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = page.items[index];
            final driverName = ((item['driver'] as Map?)?['name'] ?? '')
                .toString();
            final latestLocation = (item['latest_location'] as Map?)
                ?.cast<String, dynamic>();
            final trackingPreview = (item['tracking_preview'] as Map?)
                ?.cast<String, dynamic>();
            final mapUrl = latestLocation?['map_url']?.toString();
            final recordedAt = latestLocation?['recorded_at']?.toString();
            final canOpenMap = mapUrl != null && mapUrl.isNotEmpty;
            final shareMessage = canOpenMap
                ? 'Localizacao da rota ${(item['name'] ?? 'Rota').toString()}: $mapUrl'
                : null;

            return _InfoCard(
              title: (item['name'] ?? 'Rota #${item['id']}').toString(),
              subtitle: [
                if (driverName.isNotEmpty) 'Motorista: $driverName',
                'Status: ${(item['status'] ?? 'N/A').toString()}',
                if (recordedAt != null && recordedAt.isNotEmpty)
                  'Localizacao: ${_formatIsoDateTime(recordedAt)}',
              ].join(' • '),
              icon: Icons.route_rounded,
              footer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ParentRouteLiveMap(
                    routeItem: item,
                    latestLocation: latestLocation,
                    trackingPreview: trackingPreview,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: canOpenMap
                              ? () => _openExternalMap(context, mapUrl)
                              : null,
                          icon: const Icon(Icons.map_rounded),
                          label: const Text('Abrir mapa'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: shareMessage == null
                              ? null
                              : () => _shareRouteLink(context, shareMessage),
                          icon: const Icon(Icons.share_rounded),
                          label: const Text('Compartilhar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ParentRouteLiveMap extends StatefulWidget {
  const _ParentRouteLiveMap({
    required this.routeItem,
    required this.latestLocation,
    required this.trackingPreview,
  });

  final Map<String, dynamic> routeItem;
  final Map<String, dynamic>? latestLocation;
  final Map<String, dynamic>? trackingPreview;

  @override
  State<_ParentRouteLiveMap> createState() => _ParentRouteLiveMapState();
}

class _ParentRouteLiveMapState extends State<_ParentRouteLiveMap> {
  MapLibreMapController? _ctrl;
  bool _ready = false;

  static const _styleUrl = 'https://tiles.openfreemap.org/styles/liberty';

  @override
  void didUpdateWidget(covariant _ParentRouteLiveMap old) {
    super.didUpdateWidget(old);
    if (_ready) _syncMap();
  }

  (LatLng?, List<LatLng>, List<_ParentRouteStop>) _mapData() {
    final driverLat =
        (widget.latestLocation?['latitude'] as num?)?.toDouble();
    final driverLng =
        (widget.latestLocation?['longitude'] as num?)?.toDouble();
    final current = (driverLat != null && driverLng != null)
        ? LatLng(driverLat, driverLng)
        : null;
    final poly = _extractLatLngPolyline(widget.trackingPreview?['geometry']);
    final stops = _extractStops(widget.trackingPreview?['remaining_stops']);
    return (current, poly, stops);
  }

  Future<void> _syncMap() async {
    final c = _ctrl;
    if (c == null || !_ready) return;

    await c.clearLines();
    await c.clearCircles();

    final (current, routePolyline, stops) = _mapData();
    final fallbackPoly = <LatLng>[
      ?current,
      ...stops.map((s) => LatLng(s.lat, s.lng)),
    ];
    final displayPoly =
        routePolyline.length >= 2 ? routePolyline : fallbackPoly;
    final approx = routePolyline.length < 2 && fallbackPoly.length >= 2;

    if (displayPoly.length >= 2) {
      await c.addLine(LineOptions(
        geometry: displayPoly,
        lineColor: '#222222',
        lineWidth: 7.5,
        lineOpacity: 0.22,
        lineJoin: 'round',
      ));
      await c.addLine(LineOptions(
        geometry: displayPoly,
        lineColor: approx ? '#64B5F6' : '#FFC107',
        lineWidth: 4.5,
        lineOpacity: 1.0,
        lineJoin: 'round',
      ));
    }

    for (final s in stops) {
      await c.addCircle(CircleOptions(
        geometry: LatLng(s.lat, s.lng),
        circleRadius: 8.0,
        circleColor: '#FFFFFF',
        circleStrokeColor: '#B00020',
        circleStrokeWidth: 2.5,
      ));
    }

    if (current != null) {
      await c.addCircle(CircleOptions(
        geometry: current,
        circleRadius: 13.0,
        circleColor: '#FFD54F',
        circleStrokeColor: '#111111',
        circleStrokeWidth: 2.5,
      ));
    }

    final allPoints = <LatLng>[
      ?current,
      ...displayPoly,
      ...stops.map((s) => LatLng(s.lat, s.lng)),
    ];
    final center =
        _averageLatLng(allPoints) ?? const LatLng(-25.5401, -54.5854);
    final zoom = displayPoly.length >= 2 ? 13.2 : 15.5;
    await c.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: center, zoom: zoom),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (current, routePolyline, stops) = _mapData();
    final hasContent =
        current != null || stops.isNotEmpty || routePolyline.length >= 2;

    if (!hasContent) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E1CB)),
        ),
        child: const Text(
          'Aguardando localizacao do motorista para exibir o mapa.',
          style: TextStyle(fontSize: 13, color: AppColors.slate),
        ),
      );
    }

    final allPoints = <LatLng>[
      ?current,
      ...routePolyline,
      ...stops.map((s) => LatLng(s.lat, s.lng)),
    ];
    final center =
        _averageLatLng(allPoints) ?? const LatLng(-25.5401, -54.5854);
    final zoom = routePolyline.length >= 2 ? 13.2 : 15.5;
    final routeTitle = (widget.routeItem['name'] ?? 'Rota').toString();
    final approx = routePolyline.length < 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 260,
            width: double.infinity,
            child: MapLibreMap(
              styleString: _styleUrl,
              initialCameraPosition: CameraPosition(
                target: center,
                zoom: zoom,
              ),
              onMapCreated: (c) => _ctrl = c,
              onStyleLoadedCallback: () {
                _ready = true;
                _syncMap();
              },
              compassEnabled: false,
              myLocationEnabled: false,
              tiltGesturesEnabled: false,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _RoutePill(
              icon: Icons.route_rounded,
              text: approx ? 'Rota aproximada' : routeTitle,
            ),
            _RoutePill(
              icon: Icons.my_location_rounded,
              text: current != null ? 'Motorista ao vivo' : 'Sem GPS ao vivo',
            ),
          ],
        ),
      ],
    );
  }
}

class _RoutePill extends StatelessWidget {
  const _RoutePill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8E1CB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.ink),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

typedef _ParentRouteStop = ({double lat, double lng, String? name});

List<_ParentRouteStop> _extractStops(dynamic rawStops) {
  if (rawStops is! List) return const [];
  return rawStops
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .map((item) {
        final lat = (item['lat'] as num?)?.toDouble();
        final lng = (item['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) return null;
        return (lat: lat, lng: lng, name: item['name']?.toString());
      })
      .whereType<_ParentRouteStop>()
      .toList(growable: false);
}

List<LatLng> _extractLatLngPolyline(dynamic geometry) {
  final points = _extractLatLngPolylineAny(geometry);
  if (points.length < 2) return const [];
  return points;
}

List<LatLng> _extractLatLngPolylineAny(dynamic geometry) {
  if (geometry == null) return const [];
  if (geometry is String) {
    final text = geometry.trim();
    if (text.isEmpty) return const [];
    if (text.startsWith('{') || text.startsWith('[')) {
      try {
        return _extractLatLngPolylineAny(jsonDecode(text));
      } catch (_) {}
    }
    return _decodePolylineToLatLng(text);
  }
  if (geometry is List) {
    return _latLngFromCoordinates(geometry);
  }
  if (geometry is! Map) return const [];

  if (geometry['geometry'] != null) {
    final nested = _extractLatLngPolylineAny(geometry['geometry']);
    if (nested.length >= 2) return nested;
  }
  if (geometry['polyline'] is String) {
    final decoded = _decodePolylineToLatLng(geometry['polyline'].toString());
    if (decoded.length >= 2) return decoded;
  }

  final type = geometry['type']?.toString().toLowerCase();
  switch (type) {
    case 'feature':
      return _extractLatLngPolylineAny(geometry['geometry']);
    case 'featurecollection':
      final features = geometry['features'];
      if (features is! List) return const [];
      final merged = <LatLng>[];
      for (final feature in features) {
        final segment = _extractLatLngPolylineAny(feature);
        if (segment.isEmpty) continue;
        if (merged.isNotEmpty &&
            merged.last.latitude == segment.first.latitude &&
            merged.last.longitude == segment.first.longitude) {
          merged.addAll(segment.skip(1));
        } else {
          merged.addAll(segment);
        }
      }
      return merged;
    case 'multilinestring':
      final coordinates = geometry['coordinates'];
      if (coordinates is! List) return const [];
      final merged = <LatLng>[];
      for (final part in coordinates) {
        final segment = _latLngFromCoordinates(part);
        if (segment.isEmpty) continue;
        if (merged.isNotEmpty &&
            merged.last.latitude == segment.first.latitude &&
            merged.last.longitude == segment.first.longitude) {
          merged.addAll(segment.skip(1));
        } else {
          merged.addAll(segment);
        }
      }
      return merged;
    case 'linestring':
      return _latLngFromCoordinates(geometry['coordinates']);
    default:
      if (geometry['coordinates'] is List) {
        return _latLngFromCoordinates(geometry['coordinates']);
      }
      return const [];
  }
}

List<LatLng> _latLngFromCoordinates(dynamic coordinates) {
  if (coordinates is! List) return const [];
  final points = <LatLng>[];
  for (final item in coordinates) {
    if (item is! List || item.length < 2) continue;
    final lng = item[0];
    final lat = item[1];
    if (lat is num && lng is num) {
      points.add(LatLng(lat.toDouble(), lng.toDouble()));
    }
  }
  return points;
}

List<LatLng> _decodePolylineToLatLng(String encoded) {
  if (encoded.isEmpty) return const [];
  final points = <LatLng>[];
  var index = 0;
  var lat = 0;
  var lng = 0;
  while (index < encoded.length) {
    final latResult = _decodePolylineChunk(encoded, index);
    if (latResult == null) break;
    index = latResult.$2;
    lat += latResult.$1;

    final lngResult = _decodePolylineChunk(encoded, index);
    if (lngResult == null) break;
    index = lngResult.$2;
    lng += lngResult.$1;

    points.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return points;
}

(int, int)? _decodePolylineChunk(String encoded, int start) {
  var result = 0;
  var shift = 0;
  var index = start;
  while (index < encoded.length) {
    final byte = encoded.codeUnitAt(index++) - 63;
    result |= (byte & 0x1f) << shift;
    shift += 5;
    if (byte < 0x20) {
      final delta = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      return (delta, index);
    }
  }
  return null;
}

LatLng? _averageLatLng(List<LatLng> points) {
  if (points.isEmpty) return null;
  var lat = 0.0;
  var lng = 0.0;
  for (final p in points) {
    lat += p.latitude;
    lng += p.longitude;
  }
  return LatLng(lat / points.length, lng / points.length);
}

class _ParentBoardingsTab extends ConsumerWidget {
  const _ParentBoardingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(parentBoardingsProvider);
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorPane(message: error.toString()),
      data: (page) {
        if (page.items.isEmpty) {
          return const _EmptyPane(message: 'Nenhum embarque registrado.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: page.items.length,
          separatorBuilder: (_, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = page.items[index];
            final boarding = (item['boarding'] as Map?) ?? const {};
            final route = (boarding['route'] as Map?) ?? const {};
            final client = (item['client'] as Map?) ?? const {};
            final child = (client['child'] as Map?) ?? const {};
            final title = 'Status: ${(item['status'] ?? 'N/A').toString()}';
            final subtitle = [
              if ((child['name'] ?? '').toString().isNotEmpty)
                'Dependente: ${child['name']}',
              if ((route['name'] ?? '').toString().isNotEmpty)
                'Rota: ${route['name']}',
              if ((boarding['hour_boarding'] ?? '').toString().isNotEmpty)
                'Hora: ${boarding['hour_boarding']}',
            ].join(' • ');
            return _InfoCard(
              title: title,
              subtitle: subtitle,
              icon: Icons.login_rounded,
            );
          },
        );
      },
    );
  }
}

class _DependentAvatar extends StatelessWidget {
  const _DependentAvatar({required this.avatarUrl, required this.name});

  final String? avatarUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final hasImage = avatarUrl != null && avatarUrl!.trim().isNotEmpty;
    return CircleAvatar(
      backgroundColor: const Color(0xFFFFF1BE),
      backgroundImage: hasImage ? NetworkImage(avatarUrl!) : null,
      child: hasImage
          ? null
          : Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: const TextStyle(color: AppColors.ink),
            ),
    );
  }
}

class _DependentFormDraft {
  const _DependentFormDraft({
    required this.name,
    required this.relativeId,
    required this.schoolId,
    required this.shiftId,
    this.sex,
    this.age,
    this.avatarImagePath,
  });

  final String name;
  final int relativeId;
  final int schoolId;
  final int shiftId;
  final String? sex;
  final int? age;
  final String? avatarImagePath;
}

class _DependentFormDialog extends ConsumerStatefulWidget {
  const _DependentFormDialog({required this.onSubmit, this.current});

  final Map<String, dynamic>? current;
  final Future<void> Function(_DependentFormDraft draft) onSubmit;

  @override
  ConsumerState<_DependentFormDialog> createState() =>
      _DependentFormDialogState();
}

class _DependentFormDialogState extends ConsumerState<_DependentFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  CatalogOption? _relative;
  CatalogOption? _school;
  CatalogOption? _shift;
  String? _sex;
  String? _avatarImagePath;
  bool _saving = false;
  String? _error;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    _nameController = TextEditingController(
      text: (current?['name'] ?? '').toString(),
    );
    _ageController = TextEditingController(
      text: (current?['age'] ?? '').toString() == 'null'
          ? ''
          : (current?['age'] ?? '').toString(),
    );
    final sex = (current?['sex'] ?? '').toString().trim();
    _sex = sex.isEmpty ? null : sex;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final relativesAsync = ref.watch(relativesCatalogProvider);
    final schoolsAsync = ref.watch(schoolsCatalogProvider);
    final shiftsAsync = ref.watch(shiftsCatalogProvider);

    _ensureSelections(
      relativesAsync.valueOrNull ?? const [],
      schoolsAsync.valueOrNull ?? const [],
      shiftsAsync.valueOrNull ?? const [],
    );

    return AlertDialog(
      title: Text(
        widget.current == null ? 'Novo dependente' : 'Editar dependente',
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFFFF1BE),
                    backgroundImage: _avatarImagePath != null
                        ? FileImage(File(_avatarImagePath!))
                        : null,
                    child: _avatarImagePath == null
                        ? const Icon(Icons.photo_camera_back_outlined)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _pickImage,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Foto'),
                        ),
                        if (_avatarImagePath != null)
                          TextButton(
                            onPressed: _saving
                                ? null
                                : () => setState(() => _avatarImagePath = null),
                            child: const Text('Remover'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _sex,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Sexo (opcional)'),
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('Masculino')),
                  DropdownMenuItem(value: 'F', child: Text('Feminino')),
                  DropdownMenuItem(value: 'O', child: Text('Outro')),
                ],
                onChanged: _saving ? null : (v) => setState(() => _sex = v),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Idade (opcional)',
                ),
              ),
              const SizedBox(height: 10),
              _catalogDropdown(
                label: 'Parentesco',
                items: relativesAsync.valueOrNull ?? const [],
                value: _relative,
                onChanged: (v) => setState(() => _relative = v),
              ),
              const SizedBox(height: 10),
              _catalogDropdown(
                label: 'Escola',
                items: schoolsAsync.valueOrNull ?? const [],
                value: _school,
                onChanged: (v) => setState(() => _school = v),
              ),
              const SizedBox(height: 10),
              _catalogDropdown(
                label: 'Turno',
                items: shiftsAsync.valueOrNull ?? const [],
                value: _shift,
                onChanged: (v) => setState(() => _shift = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text(_saving ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }

  Widget _catalogDropdown({
    required String label,
    required List<CatalogOption> items,
    required CatalogOption? value,
    required ValueChanged<CatalogOption?> onChanged,
  }) {
    return DropdownButtonFormField<CatalogOption>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items
          .map(
            (item) => DropdownMenuItem<CatalogOption>(
              value: item,
              child: Text(item.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: _saving ? null : onChanged,
    );
  }

  void _ensureSelections(
    List<CatalogOption> relatives,
    List<CatalogOption> schools,
    List<CatalogOption> shifts,
  ) {
    final current = widget.current;
    if (_relative == null && current != null) {
      final relativeId =
          ((current['relative'] as Map?)?['id'] as num?)?.toInt() ??
          (current['relative_id'] as num?)?.toInt();
      if (relativeId != null) {
        _relative = _findCatalogOption(relatives, relativeId);
      }
    }
    if (_school == null && current != null) {
      final schoolId =
          ((current['school'] as Map?)?['id'] as num?)?.toInt() ??
          (current['school_id'] as num?)?.toInt();
      if (schoolId != null) {
        _school = _findCatalogOption(schools, schoolId);
      }
    }
    if (_shift == null && current != null) {
      final shiftId =
          ((current['shift'] as Map?)?['id'] as num?)?.toInt() ??
          (current['shift_id'] as num?)?.toInt();
      if (shiftId != null) {
        _shift = _findCatalogOption(shifts, shiftId);
      }
    }
  }

  CatalogOption? _findCatalogOption(List<CatalogOption> items, int id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    setState(() => _avatarImagePath = file.path);
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nome e obrigatorio.');
      return;
    }
    if (_relative == null || _school == null || _shift == null) {
      setState(() => _error = 'Selecione parentesco, escola e turno.');
      return;
    }
    final ageText = _ageController.text.trim();
    final age = ageText.isEmpty ? null : int.tryParse(ageText);
    if (ageText.isNotEmpty && age == null) {
      setState(() => _error = 'Idade invalida.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSubmit(
        _DependentFormDraft(
          name: name,
          relativeId: _relative!.id,
          schoolId: _school!.id,
          shiftId: _shift!.id,
          sex: _sex,
          age: age,
          avatarImagePath: _avatarImagePath,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'Falha ao salvar dependente.';
      });
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.leading,
    this.footer,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? leading;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading ??
                CircleAvatar(
                  backgroundColor: const Color(0xFFFFF1BE),
                  child: Icon(icon, color: AppColors.ink),
                ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
                    ),
                  ],
                  if (footer != null) ...[const SizedBox(height: 10), footer!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openExternalMap(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!context.mounted || ok) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Nao foi possivel abrir o mapa.')),
  );
}

Future<void> _shareRouteLink(BuildContext context, String message) async {
  await Clipboard.setData(ClipboardData(text: message));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Link da rota copiado para compartilhar.')),
  );
}

String _formatIsoDateTime(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  final local = parsed.toLocal();
  final dd = local.day.toString().padLeft(2, '0');
  final mm = local.month.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$dd/$mm $hh:$min';
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _EmptyPane extends StatelessWidget {
  const _EmptyPane({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.slate),
      ),
    );
  }
}
