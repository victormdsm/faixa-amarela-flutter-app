import 'package:app_faixa_amarela/core/error/app_failure.dart';
import 'package:app_faixa_amarela/features/parent_portal/data/address_forward_locator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_children_repository.dart';

class _StubChildrenRepository extends FakeChildrenRepository {
  /// Fila de comportamentos por chamada: ponto encontrado ou [NotFoundFailure].
  final List<GeocodedPoint? Function()> responses = [];
  final List<String> geocodeTexts = [];

  @override
  Future<GeocodedPoint?> geocodeAddress(String text) async {
    geocodeTexts.add(text);
    final next = responses.removeAt(0);
    return next();
  }
}

GeocodedPoint _point([String? label]) =>
    (latitude: -25.51, longitude: -54.55, label: label);

void main() {
  late _StubChildrenRepository repository;

  setUp(() {
    repository = _StubChildrenRepository();
  });

  test('forward com número monta o texto com rua, número, cidade e UF', () async {
    repository.responses.add(() => _point('Rua das Flores, 123'));

    final result = await forwardLocateAddress(
      repository,
      street: 'Rua das Flores',
      number: '123',
      cityBias: 'Foz do Iguaçu, PR',
    );

    expect(
      repository.geocodeTexts,
      ['Rua das Flores, 123, Foz do Iguaçu, PR'],
    );
    expect(result?.numberMatched, isTrue);
    expect(result?.point.latitude, -25.51);
  });

  test('sem número digitado, busca direto com rua + cidade/UF', () async {
    repository.responses.add(() => _point());

    final result = await forwardLocateAddress(
      repository,
      street: 'Rua das Flores',
      number: ' ',
      cityBias: 'Foz do Iguaçu, PR',
    );

    expect(repository.geocodeTexts, ['Rua das Flores, Foz do Iguaçu, PR']);
    // Nada a cair no fallback: sem número, o match já é o melhor possível.
    expect(result?.numberMatched, isTrue);
  });

  test('número não achado (404) cai no fallback sem número e sinaliza', () async {
    repository.responses
      ..add(() => throw const NotFoundFailure(message: 'não achou'))
      ..add(() => _point('Rua das Flores, Foz do Iguaçu'));

    final result = await forwardLocateAddress(
      repository,
      street: 'Rua das Flores',
      number: '9999',
      cityBias: 'Foz do Iguaçu, PR',
    );

    expect(repository.geocodeTexts, [
      'Rua das Flores, 9999, Foz do Iguaçu, PR',
      'Rua das Flores, Foz do Iguaçu, PR',
    ]);
    expect(result?.numberMatched, isFalse);
    expect(result?.point.label, 'Rua das Flores, Foz do Iguaçu');
  });

  test('nem a rua encontrada: retorna null para a UI avisar', () async {
    repository.responses
      ..add(() => throw const NotFoundFailure(message: 'não achou'))
      ..add(() => throw const NotFoundFailure(message: 'não achou'));

    final result = await forwardLocateAddress(
      repository,
      street: 'Rua Inexistente',
      number: '10',
      cityBias: 'Foz do Iguaçu, PR',
    );

    expect(result, isNull);
    expect(repository.geocodeTexts, hasLength(2));
  });

  test('erros que não são "não encontrado" propagam (rede/servidor)', () async {
    repository.responses.add(
      () => throw const ServerFailure(message: 'ORS fora do ar'),
    );

    expect(
      () => forwardLocateAddress(
        repository,
        street: 'Rua das Flores',
        number: '123',
        cityBias: 'Foz do Iguaçu, PR',
      ),
      throwsA(isA<ServerFailure>()),
    );
  });
}
