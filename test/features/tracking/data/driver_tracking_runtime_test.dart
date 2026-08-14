import 'dart:io';
import 'dart:typed_data';

import 'package:app_faixa_amarela/core/storage/secure_token_storage.dart';
import 'package:app_faixa_amarela/features/tracking/data/driver_tracking_runtime.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.statusCode);

  int statusCode;
  final List<RequestOptions> requests = <RequestOptions>[];

  List<String> get paths =>
      requests.map((r) => r.path).toList(growable: false);

  List<String?> get authorizationHeaders => requests
      .map((r) => r.headers['Authorization']?.toString())
      .toList(growable: false);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{"data":{"accepted":1}}',
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const baseUrl = 'https://api.faixaamarela.test/api/v1';
  late Directory tempDir;
  late SecureTokenStorage storage;
  late Box<dynamic> box;
  late List<(String, Map<String, dynamic>)> events;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('hive_tracking_runtime_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    storage = SecureTokenStorage();
    box = await DriverTrackingRuntimeTestHarness.attachBox();
    await box.clear();
    events = <(String, Map<String, dynamic>)>[];
    DriverTrackingRuntimeTestHarness.eventSink = (event, data) =>
        events.add((event, data));
  });

  tearDown(() async {
    await DriverTrackingRuntimeTestHarness.reset();
  });

  Dio buildDio(_RecordingAdapter adapter) {
    return Dio(BaseOptions(baseUrl: baseUrl))..httpClientAdapter = adapter;
  }

  Map<String, dynamic> point(int index) => <String, dynamic>{
    'timestamp': DateTime.now().toUtc().toIso8601String(),
    'lat': -25.5 + index,
    'lng': -54.5 + index,
    'speed': 30,
    'heading': 90,
  };

  List<(String, Map<String, dynamic>)> eventsOf(String name) =>
      events.where((e) => e.$1 == name).toList(growable: false);

  group('flush de telemetria em background', () {
    test('401 aplica backoff exponencial e nunca renova token no isolate', () async {
      await storage.writeAccessToken('token-expirado');
      final adapter = _RecordingAdapter(401);
      DriverTrackingRuntimeTestHarness.startRoute(
        dio: buildDio(adapter),
        apiBaseUrl: baseUrl,
        routeManifestId: 'route.42',
        vanId: 7,
      );

      final delays = <int>[];
      for (var i = 0; i < 7; i++) {
        await box.put('p$i', point(i));
        await DriverTrackingRuntimeTestHarness.flushNow();
        delays.add(DriverTrackingRuntimeTestHarness.nextFlushDelaySeconds);
      }

      expect(delays, <int>[2, 4, 8, 16, 32, 60, 60]);
      expect(
        box.length,
        7,
        reason: 'pontos so podem sair do buffer em 2xx',
      );
      expect(adapter.paths.toSet(), <String>{'/driver/telemetry/batch'});
      expect(
        adapter.paths.where((p) => p.contains('refresh')),
        isEmpty,
        reason: 'o isolate de background nunca renova o token sozinho',
      );
      expect(
        await storage.readAccessToken(),
        'token-expirado',
        reason: 'o isolate de background nao pode reescrever o token',
      );
      expect(eventsOf(trackingEventAuthExpired), hasLength(7));
      expect(
        eventsOf(trackingEventAuthExpired).last.$2['next_retry_seconds'],
        60,
      );
    });

    test('2xx apos 401 reseta o backoff', () async {
      await storage.writeAccessToken('token-valido');
      final adapter = _RecordingAdapter(401);
      DriverTrackingRuntimeTestHarness.startRoute(
        dio: buildDio(adapter),
        apiBaseUrl: baseUrl,
        routeManifestId: 'route.42',
        vanId: 7,
      );

      await box.put('p0', point(0));
      await DriverTrackingRuntimeTestHarness.flushNow();
      await DriverTrackingRuntimeTestHarness.flushNow();
      expect(DriverTrackingRuntimeTestHarness.nextFlushDelaySeconds, 4);

      adapter.statusCode = 200;
      await DriverTrackingRuntimeTestHarness.flushNow();

      expect(DriverTrackingRuntimeTestHarness.nextFlushDelaySeconds, 2);
      expect(DriverTrackingRuntimeTestHarness.authFailureStreak, 0);
      expect(box.isEmpty, isTrue);
      expect(eventsOf(trackingEventFlushSuccess), hasLength(1));
    });

    test('404 limpa o buffer, para o timer e avisa a UI', () async {
      await storage.writeAccessToken('token-valido');
      final adapter = _RecordingAdapter(404);
      DriverTrackingRuntimeTestHarness.startRoute(
        dio: buildDio(adapter),
        apiBaseUrl: baseUrl,
        routeManifestId: 'route.42',
        vanId: 7,
      );
      DriverTrackingRuntimeTestHarness.startFlushTimer();
      expect(DriverTrackingRuntimeTestHarness.flushTimerActive, isTrue);

      await box.put('p0', point(0));
      await box.put('p1', point(1));
      await DriverTrackingRuntimeTestHarness.flushNow();

      expect(box.isEmpty, isTrue);
      expect(DriverTrackingRuntimeTestHarness.flushTimerActive, isFalse);
      expect(DriverTrackingRuntimeTestHarness.flushHalted, isTrue);
      expect(eventsOf(trackingEventError), hasLength(1));
      expect(
        eventsOf(trackingEventError).single.$2['message'].toString(),
        contains('Rota ativa nao encontrada'),
      );
    });

    test('cada flush le o token atual do SecureTokenStorage', () async {
      await storage.writeAccessToken('token-1');
      final adapter = _RecordingAdapter(200);
      DriverTrackingRuntimeTestHarness.startRoute(
        dio: buildDio(adapter),
        apiBaseUrl: baseUrl,
        routeManifestId: 'route.42',
        vanId: 7,
        authHeader: 'Bearer token-cacheado-obsoleto',
      );

      await box.put('p0', point(0));
      await DriverTrackingRuntimeTestHarness.flushNow();

      await storage.writeAccessToken('token-2');

      await box.put('p1', point(1));
      await DriverTrackingRuntimeTestHarness.flushNow();

      expect(adapter.authorizationHeaders, <String>[
        'Bearer token-1',
        'Bearer token-2',
      ]);
    });

    test('sem token no storage cai para o header de tracking:update_auth', () async {
      final adapter = _RecordingAdapter(200);
      DriverTrackingRuntimeTestHarness.startRoute(
        dio: buildDio(adapter),
        apiBaseUrl: baseUrl,
        routeManifestId: 'route.42',
        vanId: 7,
        authHeader: 'Bearer header-via-ipc',
      );

      await box.put('p0', point(0));
      await DriverTrackingRuntimeTestHarness.flushNow();

      expect(adapter.authorizationHeaders.single, 'Bearer header-via-ipc');
    });
  });
}
