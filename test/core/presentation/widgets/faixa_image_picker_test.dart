import 'package:app_faixa_amarela/core/presentation/widgets/faixa_image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FaixaImagePicker.vehicle', () {
    testWidgets('renderiza em proporção 4:3', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FaixaImagePicker.vehicle(
              onTap: () {},
            ),
          ),
        ),
      );
      // Não usa pumpAndSettle: o empty-state não dispara requisições, mas
      // garante um frame de layout para que o AspectRatio seja aplicado.
      await tester.pump();

      final aspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspectRatio.aspectRatio, closeTo(4 / 3, 0.001));
    });
  });
}
