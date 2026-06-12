import 'package:app_faixa_amarela/core/utils/debouncer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debouncer delays action', () async {
    var callCount = 0;
    final debouncer = Debouncer(delay: const Duration(milliseconds: 50));

    debouncer.run(() => callCount++);
    debouncer.run(() => callCount++);
    debouncer.run(() => callCount++);

    expect(callCount, 0);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(callCount, 1);

    debouncer.dispose();
  });

  test('debouncer cancels previous timer', () async {
    var callCount = 0;
    final debouncer = Debouncer(delay: const Duration(milliseconds: 100));

    debouncer.run(() => callCount++);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    debouncer.run(() => callCount++);

    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(callCount, 1);

    debouncer.dispose();
  });
}
