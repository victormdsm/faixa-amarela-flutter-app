import 'dart:convert';
import 'dart:io';

import 'package:app_faixa_amarela/core/presentation/widgets/full_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // PNG 1x1 válido para o Image.file decodificar sem erro assíncrono.
  late File imageFile;

  setUpAll(() async {
    const pngBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
    final dir = await Directory.systemTemp.createTemp('faixa_viewer_test');
    imageFile = File('${dir.path}/photo.png');
    await imageFile.writeAsBytes(base64Decode(pngBase64));
  });

  Widget buildApp(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('FullImageViewerEyeButton', () {
    testWidgets('não renderiza nada quando não há imagem', (tester) async {
      await tester.pumpWidget(
        buildApp(const FullImageViewerEyeButton()),
      );

      expect(find.byType(IconButton), findsNothing);
      expect(find.byIcon(Icons.remove_red_eye_rounded), findsNothing);
    });

    testWidgets('renderiza o olho quando há imagem local', (tester) async {
      await tester.pumpWidget(
        buildApp(FullImageViewerEyeButton(localPath: imageFile.path)),
      );

      expect(find.byIcon(Icons.remove_red_eye_rounded), findsOneWidget);
    });

    testWidgets('abre o viewer com zoom e fecha pelo botão', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          buildApp(FullImageViewerEyeButton(localPath: imageFile.path)),
        );

        await tester.tap(find.byIcon(Icons.remove_red_eye_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      });

      expect(find.byType(FullImageViewer), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      });

      expect(find.byType(FullImageViewer), findsNothing);
    });

    testWidgets('o olho não dispara o onTap de troca de foto vizinho',
        (tester) async {
      var swapTaps = 0;

      await tester.runAsync(() async {
        await tester.pumpWidget(
          buildApp(
            GestureDetector(
              onTap: () => swapTaps++,
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    const Positioned.fill(child: ColoredBox(color: Colors.red)),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: FullImageViewerEyeButton(
                        localPath: imageFile.path,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.remove_red_eye_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      });

      expect(swapTaps, 0);
      expect(find.byType(FullImageViewer), findsOneWidget);
    });
  });

  group('FullImageViewer', () {
    testWidgets('mostra fallback quando não há imagem', (tester) async {
      await tester.pumpWidget(buildApp(const FullImageViewer()));

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });
  });
}
