import 'package:app_faixa_amarela/core/storage/secure_token_storage.dart';
import 'package:app_faixa_amarela/features/auth/data/session_storage.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_session.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureTokenStorage extends Mock implements SecureTokenStorage {}

class MockBox extends Mock implements Box<dynamic> {}

void main() {
  late MockSecureTokenStorage secureStorage;
  late MockBox box;
  late SessionStorage storage;

  setUp(() {
    secureStorage = MockSecureTokenStorage();
    box = MockBox();
    storage = SessionStorage(secureStorage: secureStorage, box: box);
  });

  group('SessionStorage', () {
    test('save writes token only to secure storage, not to Hive', () async {
      const token = 'super_secret_access_token';
      final session = AuthSession(
        accessToken: token,
        tokenType: 'Bearer',
        user: const AuthUser(
          id: 1,
          name: 'Maria',
          email: 'maria@email.com',
          role: 'user',
          isActivated: true,
        ),
      );

      when(
        () => secureStorage.writeAccessToken(token),
      ).thenAnswer((_) async {});
      when(() => box.putAll(any())).thenAnswer((_) async {});

      await storage.save(session);

      verify(() => secureStorage.writeAccessToken(token)).called(1);

      final captured =
          verify(() => box.putAll(captureAny())).captured.single
              as Map<dynamic, dynamic>;
      expect(captured['user_id'], 1);
      expect(captured['user_name'], 'Maria');
      expect(captured.containsKey('access_token'), isFalse);
      expect(
        captured.values.where((v) => v.toString().contains(token)).isEmpty,
        isTrue,
        reason: 'Hive putAll must not contain the raw access token',
      );
    });

    test('load reads token from secure storage and builds session', () async {
      const token = 'stored_secure_token';

      when(
        () => secureStorage.readAccessToken(),
      ).thenAnswer((_) async => token);
      when(() => box.get('user_id')).thenReturn(2);
      when(() => box.get('user_name')).thenReturn('Joao');
      when(() => box.get('user_email')).thenReturn('joao@email.com');
      when(() => box.get('user_role')).thenReturn('driver');
      when(() => box.get('user_is_activated')).thenReturn(true);
      when(() => box.get('token_type')).thenReturn('Bearer');
      when(() => box.get('expires_at')).thenReturn(null);

      final session = await storage.load();

      expect(session, isNotNull);
      expect(session!.accessToken, token);
      expect(session.user.id, 2);
      expect(session.user.role, 'driver');
    });

    test('load returns null when secure storage token is missing', () async {
      when(() => secureStorage.readAccessToken()).thenAnswer((_) async => null);
      when(() => box.get('user_id')).thenReturn(3);
      when(() => box.get('user_role')).thenReturn('user');

      final session = await storage.load();

      expect(session, isNull);
    });

    test('clear wipes secure storage and Hive box', () async {
      when(() => secureStorage.clearAll()).thenAnswer((_) async {});
      when(() => box.clear()).thenAnswer((_) async => 0);

      await storage.clear();

      verify(() => secureStorage.clearAll()).called(1);
      verify(() => box.clear()).called(1);
    });
  });
}
