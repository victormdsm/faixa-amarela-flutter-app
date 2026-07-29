import 'package:app_faixa_amarela/core/models/catalog_option.dart';
import 'package:app_faixa_amarela/features/parent_portal/presentation/widgets/address_autofill.dart';
import 'package:app_faixa_amarela/features/parent_portal/presentation/widgets/address_map_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('autofillTextValue', () {
    test('reverse NUNCA sobrescreve campo já preenchido pelo usuário', () {
      final value = autofillTextValue(
        current: 'Rua Digitada',
        incoming: 'Rua do Reverse',
        source: AddressResolveSource.reverse,
      );

      expect(value, 'Rua Digitada');
    });

    test('reverse preenche campo vazio', () {
      final value = autofillTextValue(
        current: '  ',
        incoming: 'Rua do Reverse',
        source: AddressResolveSource.reverse,
      );

      expect(value, 'Rua do Reverse');
    });

    test('reverse preserva o número digitado quando a sugestão não tem', () {
      final value = autofillTextValue(
        current: '123',
        incoming: null,
        source: AddressResolveSource.reverse,
      );

      expect(value, '123');
    });

    test('search (escolha explícita) sobrescreve com o valor da sugestão', () {
      final value = autofillTextValue(
        current: 'Rua Digitada',
        incoming: 'Rua da Sugestão',
        source: AddressResolveSource.search,
      );

      expect(value, 'Rua da Sugestão');
    });

    test('search preserva o número digitado quando a sugestão não tem '
        '(ex.: venue/condomínio)', () {
      final value = autofillTextValue(
        current: '456',
        incoming: '',
        source: AddressResolveSource.search,
      );

      expect(value, '456');
    });
  });

  group('autofillStateUf', () {
    test('reverse não troca UF já selecionada', () {
      final uf = autofillStateUf(
        currentUf: 'PR',
        incomingState: 'SP',
        source: AddressResolveSource.reverse,
      );

      expect(uf, 'PR');
    });

    test('reverse preenche UF vazia com sigla válida', () {
      final uf = autofillStateUf(
        currentUf: null,
        incomingState: 'pr',
        source: AddressResolveSource.reverse,
      );

      expect(uf, 'PR');
    });

    test('search troca a UF quando a sugestão traz outra válida', () {
      final uf = autofillStateUf(
        currentUf: 'PR',
        incomingState: 'SP',
        source: AddressResolveSource.search,
      );

      expect(uf, 'SP');
    });

    test('UF inválida/ausente mantém a atual', () {
      expect(
        autofillStateUf(
          currentUf: 'PR',
          incomingState: 'XX',
          source: AddressResolveSource.search,
        ),
        'PR',
      );
      expect(
        autofillStateUf(
          currentUf: 'PR',
          incomingState: null,
          source: AddressResolveSource.search,
        ),
        'PR',
      );
    });
  });

  group('autofillCity', () {
    const catalog = [
      CatalogOption(id: 1, name: 'Foz do Iguaçu'),
      CatalogOption(id: 2, name: 'Curitiba'),
    ];
    const curitiba = CatalogOption(id: 2, name: 'Curitiba');

    test('reverse não troca cidade já selecionada', () {
      final city = autofillCity(
        currentCity: curitiba,
        incomingCityName: 'Foz do Iguaçu',
        catalog: catalog,
        source: AddressResolveSource.reverse,
      );

      expect(city, curitiba);
    });

    test('reverse preenche cidade vazia somente com match exato no catálogo',
        () {
      final city = autofillCity(
        currentCity: null,
        incomingCityName: 'foz do iguaçu',
        catalog: catalog,
        source: AddressResolveSource.reverse,
      );

      expect(city?.id, 1);
    });

    test('sem match exato no catálogo, mantém a cidade atual (sem chute)', () {
      final city = autofillCity(
        currentCity: null,
        incomingCityName: 'Foz do Iguacu', // sem acento: não casa
        catalog: catalog,
        source: AddressResolveSource.search,
      );

      expect(city, isNull);
    });

    test('search troca a cidade quando a sugestão casa com o catálogo', () {
      final city = autofillCity(
        currentCity: curitiba,
        incomingCityName: 'Foz do Iguaçu',
        catalog: catalog,
        source: AddressResolveSource.search,
      );

      expect(city?.id, 1);
    });
  });
}
