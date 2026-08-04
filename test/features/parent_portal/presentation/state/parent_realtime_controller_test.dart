import 'package:app_faixa_amarela/features/parent_portal/data/parent_realtime_service.dart';
import 'package:app_faixa_amarela/features/parent_portal/presentation/providers/parent_portal_providers.dart';
import 'package:app_faixa_amarela/features/parent_portal/presentation/state/parent_realtime_controller.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_parent_realtime_socket.dart';

void main() {
  group('ParentRealtimeController — tolerância antes de virar "problema"', () {
    test('queda sem conexão só vira problema após 30s e limpa ao voltar', () {
      fakeAsync((async) {
        final h = _Harness();
        h.controller.watchRoute(routeId: 7, token: 'token-abc');
        async.flushMicrotasks();

        // Transitório: conexão caindo não é erro para o usuário.
        async.elapse(const Duration(seconds: 29));
        expect(h.state.isLive, isFalse);
        expect(h.state.connectionIssue, isFalse);

        // Persistente: 30s+ sem conectar.
        async.elapse(const Duration(seconds: 2));
        expect(h.state.connectionIssue, isTrue);

        // Conexão restabelecida limpa a flag na hora.
        h.socket.simulateConnect();
        async.flushMicrotasks();
        expect(h.state.isLive, isTrue);
        expect(h.state.connectionIssue, isFalse);

        h.dispose();
      });
    });

    test('queda após estar ao vivo reabre tolerância cheia (sem flag antes)', () {
      fakeAsync((async) {
        final h = _Harness();
        h.controller.watchRoute(routeId: 7, token: 'token-abc');
        h.socket.simulateConnect();
        async.flushMicrotasks();
        expect(h.state.isLive, isTrue);

        h.socket.simulateDisconnect();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 10));
        expect(h.state.connectionIssue, isFalse);

        h.dispose();
      });
    });

    test('retry descarta o socket travado, zera a flag e volta a conectar', () {
      fakeAsync((async) {
        final h = _Harness();
        h.controller.watchRoute(routeId: 7, token: 'token-abc');
        async.elapse(const Duration(seconds: 31));
        expect(h.state.connectionIssue, isTrue);

        h.controller.retry();
        async.flushMicrotasks();

        expect(h.state.connectionIssue, isFalse);
        expect(h.sockets, hasLength(2));
        expect(h.sockets.first.disposed, isTrue);
        expect(h.service.status, ParentRealtimeStatus.connecting);

        h.sockets.last.simulateConnect();
        async.flushMicrotasks();
        expect(h.state.isLive, isTrue);
        expect(h.state.connectionIssue, isFalse);

        h.dispose();
      });
    });

    test('rota encerrada (unwatch) cancela a tolerância e não acusa problema', () {
      fakeAsync((async) {
        final h = _Harness();
        h.controller.watchRoute(routeId: 7, token: 'token-abc');
        async.flushMicrotasks();

        h.controller.unwatch();
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 2));

        expect(h.state.routeId, isNull);
        expect(h.state.connectionIssue, isFalse);

        h.dispose();
      });
    });
  });
}

/// Sobe o controller dentro de um ProviderContainer com o service real
/// apontado para sockets fake, tudo na zona do fakeAsync.
class _Harness {
  _Harness() {
    service = ParentRealtimeService(
      baseUrl: 'http://localhost:3000',
      socketFactory: ({required baseUrl, required token}) {
        final socket = FakeParentRealtimeSocket();
        sockets.add(socket);
        return socket;
      },
    );
    container = ProviderContainer(
      overrides: [parentRealtimeServiceProvider.overrideWithValue(service)],
    );
    // Segura um listener para o provider autoDispose não ser descartado.
    sub = container.listen(parentRealtimeControllerProvider, (_, _) {});
  }

  late final ParentRealtimeService service;
  late final ProviderContainer container;
  late final ProviderSubscription<ParentRealtimeState> sub;
  final sockets = <FakeParentRealtimeSocket>[];

  ParentRealtimeController get controller =>
      container.read(parentRealtimeControllerProvider.notifier);
  ParentRealtimeState get state =>
      container.read(parentRealtimeControllerProvider);
  FakeParentRealtimeSocket get socket => sockets.last;

  void dispose() {
    sub.close();
    container.dispose();
  }
}
