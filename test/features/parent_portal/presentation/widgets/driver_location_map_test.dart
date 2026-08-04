import 'package:app_faixa_amarela/features/parent_portal/presentation/widgets/driver_location_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  Widget buildSubject({LatLng? driverPos, List<LatLng> schoolPoints = const []}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 600,
          child: DriverLocationMap(
            driverPos: driverPos,
            schoolPoints: schoolPoints,
          ),
        ),
      ),
    );
  }

  group('DriverLocationMap', () {
    testWidgets('renderiza marker da escola quando há schoolPoints', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          driverPos: const LatLng(-25.54, -54.58),
          // Próximo do centro: o flutter_map faz culling de markers fora do
          // viewport.
          schoolPoints: const [LatLng(-25.5405, -54.5805)],
        ),
      );
      await tester.pump();

      // Glyph de escola (marker da âncora) + glyph da van (ônibus).
      expect(find.byIcon(Icons.school_rounded), findsOneWidget);
      expect(find.byIcon(Icons.directions_bus_rounded), findsOneWidget);

      final markerLayers = tester
          .widgetList<MarkerLayer>(find.byType(MarkerLayer))
          .toList();
      final markerCount = markerLayers.fold<int>(
        0,
        (sum, layer) => sum + layer.markers.length,
      );
      expect(markerCount, 2);
    });

    testWidgets('sem schoolPoints renderiza apenas a van', (tester) async {
      await tester.pumpWidget(
        buildSubject(driverPos: const LatLng(-25.54, -54.58)),
      );
      await tester.pump();

      expect(find.byIcon(Icons.directions_bus_rounded), findsOneWidget);
      expect(find.byIcon(Icons.school_rounded), findsNothing);
    });

    testWidgets('renderiza uma escola por ponto (multi-escola)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          driverPos: const LatLng(-25.54, -54.58),
          schoolPoints: const [
            LatLng(-25.5405, -54.5805),
            LatLng(-25.5395, -54.5795),
          ],
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.school_rounded), findsNWidgets(2));
    });
  });
}
