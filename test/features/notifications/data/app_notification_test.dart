import 'dart:convert';

import 'package:app_faixa_amarela/features/notifications/data/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppNotification.fromJson', () {
    test('lê title/body do topo (contrato atual do backend)', () {
      final n = AppNotification.fromJson({
        'id': '1',
        'type': 'general',
        'title': 'Alerta do motorista',
        'body': 'Pneu furou! Vou trocar e volto em 20 minutos.',
        'data': <String, dynamic>{},
        'createdAt': '2026-07-08T09:15:00.000Z',
        'readAt': null,
      });

      expect(n.title, 'Alerta do motorista');
      expect(n.body, 'Pneu furou! Vou trocar e volto em 20 minutos.');
      expect(n.createdAt, DateTime.parse('2026-07-08T09:15:00.000Z'));
      expect(n.isUnread, isTrue);
    });

    test(
      'body vazio no topo cai para data.custom_message (alerta legado do Laravel)',
      () {
        final n = AppNotification.fromJson({
          'id': '2',
          'type': 'driver_alert',
          'title': '',
          'body': '',
          'data': {
            'title': 'Alerta do motorista',
            'custom_message': 'Pneu furou! Aguardem no ponto.',
            'driver_name': 'Seu Zé',
          },
          'createdAt': '2026-07-08T09:15:00.000Z',
        });

        expect(n.title, 'Alerta do motorista');
        expect(n.body, 'Pneu furou! Aguardem no ponto.');
      },
    );

    test('sem custom_message, cai para data.body e depois data.message', () {
      final fromDataBody = AppNotification.fromJson({
        'id': '3',
        'type': 'driver_alert',
        'body': '',
        'data': {'body': 'A van quebrou. Já chamei o reboque.'},
      });
      expect(fromDataBody.body, 'A van quebrou. Já chamei o reboque.');

      final fromDataMessage = AppNotification.fromJson({
        'id': '4',
        'type': 'general',
        'body': '',
        'data': {'message': 'Chegando ao ponto em 5 minutos.'},
      });
      expect(fromDataMessage.body, 'Chegando ao ponto em 5 minutos.');
    });

    test('body do topo tem prioridade sobre qualquer mensagem em data', () {
      final n = AppNotification.fromJson({
        'id': '5',
        'type': 'driver_alert',
        'title': 'Alerta do motorista',
        'body': 'Pneu furou! Texto real do body.',
        'data': {
          'custom_message': 'texto duplicado em data',
          'message': 'outro texto em data',
        },
      });

      expect(n.body, 'Pneu furou! Texto real do body.');
    });

    test('decodifica data enviado como String JSON (coluna text legada)', () {
      final n = AppNotification.fromJson({
        'id': '6',
        'type': 'driver_alert',
        'title': '',
        'body': '',
        'data': jsonEncode({
          'title': 'Alerta: pneu furou',
          'custom_message': 'Pneu furou! Vou trocar e volto em 20 minutos.',
        }),
      });

      expect(n.title, 'Alerta: pneu furou');
      expect(n.body, 'Pneu furou! Vou trocar e volto em 20 minutos.');
      // O JSON cru nunca vira conteúdo exibível: data vira Map tipado.
      expect(n.data['custom_message'], isA<String>());
    });

    test('data inválido não quebra o parse nem vaza texto cru', () {
      final n = AppNotification.fromJson({
        'id': '7',
        'type': 'general',
        'title': 'Aviso',
        'body': 'Conteúdo normal.',
        'data': '{json quebrado',
      });

      expect(n.title, 'Aviso');
      expect(n.body, 'Conteúdo normal.');
      expect(n.data, isEmpty);
    });

    test('sem título em lugar nenhum cai para "Notificação"', () {
      final n = AppNotification.fromJson({
        'id': '8',
        'type': 'general',
        'title': '',
        'body': '',
        'data': <String, dynamic>{},
      });

      expect(n.title, 'Notificação');
      expect(n.body, '');
    });
  });
}
