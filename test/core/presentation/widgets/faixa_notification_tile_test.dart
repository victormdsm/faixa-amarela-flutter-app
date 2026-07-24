import 'package:app_faixa_amarela/core/presentation/widgets/faixa_notification_tile.dart';
import 'package:app_faixa_amarela/features/notifications/data/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FaixaNotificationTile', () {
    testWidgets('renders title, body and unread indicator',
        (tester) async {
      final notification = AppNotification(
        id: '1',
        type: 'boarded',
        title: 'Embarque realizado',
        body: 'Ana embarcou na van.',
        data: const {},
        createdAt: DateTime(2026, 7, 8, 8, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FaixaNotificationTile(notification: notification),
          ),
        ),
      );

      expect(find.text('Embarque realizado'), findsOneWidget);
      expect(find.text('Ana embarcou na van.'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      final notification = AppNotification(
        id: '2',
        type: 'system',
        title: 'Aviso',
        body: 'Mensagem do sistema',
        data: const {},
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FaixaNotificationTile(
              notification: notification,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aviso'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
