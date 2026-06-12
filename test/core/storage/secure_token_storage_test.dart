import 'package:app_faixa_amarela/core/storage/secure_token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SecureTokenStorage storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = SecureTokenStorage();
  });

  test('write and read access token', () async {
    await storage.writeAccessToken('access_123');
    final token = await storage.readAccessToken();
    expect(token, 'access_123');
  });

  test('write and read refresh token', () async {
    await storage.writeRefreshToken('refresh_456');
    final token = await storage.readRefreshToken();
    expect(token, 'refresh_456');
  });

  test('clearAll removes tokens', () async {
    await storage.writeAccessToken('access_123');
    await storage.writeRefreshToken('refresh_456');

    await storage.clearAll();

    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readRefreshToken(), isNull);
  });
}
