import 'package:app_faixa_amarela/features/parent_portal/data/parent_realtime_service.dart';

/// Socket fake compartilhado pelos testes do realtime do pai: disparo manual
/// de connect/disconnect/eventos, sem rede.
class FakeParentRealtimeSocket implements ParentRealtimeSocket {
  final handlers = <String, List<void Function(dynamic)>>{};
  final emissions = <(String, Map<String, dynamic>)>[];
  final ackEmissions =
      <(String, Map<String, dynamic>, void Function(dynamic)?)>[];
  void Function(dynamic)? connectHandler;
  void Function(dynamic)? disconnectHandler;
  void Function(dynamic)? connectErrorHandler;
  bool disposed = false;
  bool _connected = false;

  @override
  bool get connected => _connected;

  @override
  void connect() {}

  @override
  void onConnect(void Function(dynamic data) handler) =>
      connectHandler = handler;

  @override
  void onDisconnect(void Function(dynamic data) handler) =>
      disconnectHandler = handler;

  @override
  void onConnectError(void Function(dynamic data) handler) =>
      connectErrorHandler = handler;

  @override
  void on(String event, void Function(dynamic data) handler) =>
      handlers.putIfAbsent(event, () => []).add(handler);

  @override
  void off(String event) => handlers.remove(event);

  @override
  void emit(String event, Map<String, dynamic> data) =>
      emissions.add((event, data));

  @override
  void emitWithAck(
    String event,
    Map<String, dynamic> data, {
    void Function(dynamic response)? ack,
  }) =>
      ackEmissions.add((event, data, ack));

  @override
  void dispose() {
    disposed = true;
    _connected = false;
  }

  void simulateConnect() {
    _connected = true;
    connectHandler?.call(null);
  }

  void simulateDisconnect() {
    _connected = false;
    disconnectHandler?.call(null);
  }

  void simulateLocation(Map<String, dynamic> payload) {
    for (final handler
        in handlers[ParentRealtimeService.eventLocationUpdated] ??
            const <void Function(dynamic)>[]) {
      handler(payload);
    }
  }

  void simulateRouteStatus(Map<String, dynamic> payload) {
    for (final handler
        in handlers[ParentRealtimeService.eventRouteStatusUpdated] ??
            const <void Function(dynamic)>[]) {
      handler(payload);
    }
  }

  void simulateBoardingStatus(Map<String, dynamic> payload) {
    for (final handler
        in handlers[ParentRealtimeService.eventBoardingStatusUpdated] ??
            const <void Function(dynamic)>[]) {
      handler(payload);
    }
  }
}
