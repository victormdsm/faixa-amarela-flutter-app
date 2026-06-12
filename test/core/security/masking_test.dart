import 'package:app_faixa_amarela/core/security/masking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Masking.cpf', () {
    test('masks full CPF', () {
      expect(Masking.cpf('12345678901'), '***.***.789-01');
    });

    test('returns *** for null', () {
      expect(Masking.cpf(null), '***');
    });

    test('returns *** for invalid length', () {
      expect(Masking.cpf('123'), '***');
    });
  });

  group('Masking.cpfLastDigits', () {
    test('shows last 3 digits', () {
      expect(Masking.cpfLastDigits('12345678901'), '***-901');
    });

    test('returns *** for short input', () {
      expect(Masking.cpfLastDigits('12'), '***');
    });
  });

  group('Masking.email', () {
    test('masks local part', () {
      expect(Masking.email('joao.silva@email.com'), 'j********a@email.com');
    });

    test('returns *** for invalid email', () {
      expect(Masking.email('notanemail'), '***');
    });

    test('returns *** for null', () {
      expect(Masking.email(null), '***');
    });
  });

  group('Masking.phone', () {
    test('masks all but last 4 digits', () {
      expect(Masking.phone('11987654321'), '*******4321');
    });

    test('returns *** for short input', () {
      expect(Masking.phone('123'), '***');
    });
  });

  group('Masking.token', () {
    test('shows first and last 4 chars', () {
      expect(Masking.token('abcdef1234567890'), 'abcd...7890');
    });

    test('masks short token entirely', () {
      expect(Masking.token('abc'), '***');
    });
  });

  group('Masking.redactJson', () {
    test('redacts sensitive keys', () {
      final input = <String, dynamic>{
        'name': 'Joao',
        'cpf': '12345678901',
        'email': 'joao@email.com',
        'password': 'secret',
        'access_token': 'abc123def456',
        'cell_phone': '11987654321',
      };
      final result = Masking.redactJson(input);
      expect(result['name'], 'Joao');
      expect(result['cpf'], '***-901');
      expect(result['email'], 'j**o@email.com');
      expect(result['password'], '***');
      expect(result['access_token'], 'abc1...f456');
      expect(result['cell_phone'], '*******4321');
    });

    test('redacts nested objects', () {
      final input = <String, dynamic>{
        'user': <String, dynamic>{'cpf': '12345678901', 'name': 'Maria'},
      };
      final result = Masking.redactJson(input);
      expect((result['user'] as Map<String, dynamic>)['cpf'], '***-901');
      expect((result['user'] as Map<String, dynamic>)['name'], 'Maria');
    });
  });
}
