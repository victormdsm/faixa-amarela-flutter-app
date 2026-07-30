import 'package:app_faixa_amarela/features/parent_portal/presentation/widgets/parent_route_status_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    // routeStatusSubtitle formata horário via DateFormat pt_BR.
    await initializeDateFormatting('pt_BR');
  });

  group('routeStatusSubtitle (APP-09)', () {
    test('usa driver.name, van.plate e activeManifest.startedAt do payload real', () {
      final subtitle = routeStatusSubtitle(<String, dynamic>{
        'id': 3,
        'status': 'active',
        'driver': <String, dynamic>{
          'id': 1,
          'name': 'João Silva',
          'avatarUrl': null,
        },
        'van': <String, dynamic>{
          'id': 2,
          'plate': 'abc1d23',
          'model': 'Ducato',
        },
        'activeManifest': <String, dynamic>{
          'id': 'm1',
          'status': 'active',
          'startedAt': '2026-07-30T12:30:00.000Z',
        },
      });

      expect(subtitle, contains('João Silva'));
      expect(subtitle, contains('ABC1D23'));
      expect(subtitle, contains('Saída: '));
      // O horário exato depende do fuso local — o rótulo deve vir acompanhado
      // de um HH:mm válido.
      expect(
        RegExp(r'Saída: \d{2}:\d{2}').hasMatch(subtitle),
        isTrue,
        reason: subtitle,
      );
    });

    test('cai no startedAt da rota quando o manifesto não tem startedAt', () {
      final subtitle = routeStatusSubtitle(<String, dynamic>{
        'status': 'active',
        'startedAt': '2026-07-30T12:30:00.000Z',
        'driver': <String, dynamic>{'name': 'João'},
        'activeManifest': <String, dynamic>{'id': 'm1', 'startedAt': null},
      });

      expect(subtitle, contains('João'));
      expect(RegExp(r'Saída: \d{2}:\d{2}').hasMatch(subtitle), isTrue);
    });

    test('tolera startedAt inválido sem quebrar', () {
      final subtitle = routeStatusSubtitle(<String, dynamic>{
        'status': 'active',
        'driver': <String, dynamic>{'name': 'João'},
        'activeManifest': <String, dynamic>{'startedAt': 'não-é-data'},
      });

      expect(subtitle, 'João');
    });

    test('sem detalhes retorna o fallback orientando o mapa', () {
      final subtitle = routeStatusSubtitle(<String, dynamic>{
        'status': 'active',
      });

      expect(subtitle, 'Toque em "Ver no mapa" para acompanhar.');
    });

    test('sem rota ativa retorna a mensagem de vazio', () {
      expect(routeStatusSubtitle(null), 'Nenhuma rota ativa no momento.');
      expect(
        routeStatusSubtitle(const <String, dynamic>{}),
        'Nenhuma rota ativa no momento.',
      );
    });
  });
}
