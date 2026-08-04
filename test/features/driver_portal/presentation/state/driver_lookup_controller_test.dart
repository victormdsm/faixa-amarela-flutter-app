import 'package:app_faixa_amarela/core/error/app_failure.dart';
import 'package:app_faixa_amarela/core/network/api_exception.dart';
import 'package:app_faixa_amarela/domain/repositories/enrollments_repository.dart';
import 'package:app_faixa_amarela/features/driver_portal/presentation/providers/driver_portal_providers.dart';
import 'package:app_faixa_amarela/features/driver_portal/presentation/state/driver_lookup_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_enrollments_repository.dart';

class _StubEnrollmentsRepository extends FakeEnrollmentsRepository {
  String? lastLookupCode;
  Object? lookupError;

  @override
  Future<ChildLookupResult> lookupChildByCode(String code) async {
    lastLookupCode = code;
    final error = lookupError;
    if (error != null) throw error;
    return const ChildLookupResult(found: true, childId: 10, childName: 'Ana');
  }
}

void main() {
  const validUuid = 'A1B2C3D4-E5F6-4A1B-8C2D-9E0F1A2B3C4D';
  const backend400Message =
      'Use o código da criança para buscar. Peça ao responsável que '
      'compartilhe o código no aplicativo.';

  late ProviderContainer container;
  late _StubEnrollmentsRepository repository;

  DriverLookupController controller() =>
      container.read(driverLookupControllerProvider.notifier);

  AsyncValue<ChildLookupResult?> currentState() =>
      container.read(driverLookupControllerProvider);

  setUp(() {
    repository = _StubEnrollmentsRepository();
    container = ProviderContainer(
      overrides: [
        driverEnrollmentsRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('DriverLookupController.search', () {
    test('aceita código UUID e delega ao repositório em lowercase', () async {
      controller().search(validUuid);
      expect(currentState(), isA<AsyncLoading>());

      // Debouncer de 600ms do controller.
      await Future<void>.delayed(const Duration(milliseconds: 700));

      expect(repository.lastLookupCode, validUuid.toLowerCase());
      final result = currentState().value;
      expect(result?.found, isTrue);
      expect(result?.childId, 10);
    });

    test('rejeita CPF com hint e não chama o repositório', () {
      controller().search('123.456.789-09');

      final state = currentState();
      expect(state.hasError, isTrue);
      final error = state.asError?.error;
      expect(error, isA<ValidationFailure>());
      expect(
        (error! as ValidationFailure).message,
        DriverLookupController.invalidCodeMessage,
      );
      expect(repository.lastLookupCode, isNull);
    });

    test('rejeita campo vazio com o mesmo hint', () {
      controller().search('   ');

      final state = currentState();
      expect(state.hasError, isTrue);
      final error = state.asError?.error;
      expect(error, isA<ValidationFailure>());
      expect(
        (error! as ValidationFailure).message,
        DriverLookupController.invalidCodeMessage,
      );
      expect(repository.lastLookupCode, isNull);
    });

    test('propaga a mensagem real do 400 do backend', () async {
      repository.lookupError = ApiException(
        message: backend400Message,
        statusCode: 400,
      );

      controller().search(validUuid.toLowerCase());
      await Future<void>.delayed(const Duration(milliseconds: 700));

      final state = currentState();
      expect(state.hasError, isTrue);
      final error = state.asError?.error;
      expect(error, isA<ApiException>());
      expect((error! as ApiException).message, backend400Message);
      expect((error as ApiException).statusCode, 400);
    });
  });
}
