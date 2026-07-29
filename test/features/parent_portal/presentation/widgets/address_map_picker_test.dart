import 'package:app_faixa_amarela/domain/models/address_suggestion.dart';
import 'package:app_faixa_amarela/features/parent_portal/presentation/providers/parent_portal_providers.dart';
import 'package:app_faixa_amarela/features/parent_portal/presentation/widgets/address_map_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../../../fakes/fake_children_repository.dart';

class _StubChildrenRepository extends FakeChildrenRepository {
  List<AddressSuggestion> autocompleteResults = const [];
  AddressSuggestion reverseResult = const AddressSuggestion(
    label: 'Rua Nova, 50 - Centro, Curitiba/PR',
    street: 'Rua Nova',
    number: '50',
    district: 'Centro',
    city: 'Curitiba',
    state: 'PR',
  );

  int autocompleteCalls = 0;
  int reverseCalls = 0;
  String? lastAutocompleteText;
  String? lastAutocompleteCity;

  @override
  Future<List<AddressSuggestion>> autocompleteAddress(
    String text, {
    String? city,
  }) async {
    autocompleteCalls++;
    lastAutocompleteText = text;
    lastAutocompleteCity = city;
    return autocompleteResults;
  }

  @override
  Future<AddressSuggestion> reverseAddress({
    required double latitude,
    required double longitude,
  }) async {
    reverseCalls++;
    return reverseResult;
  }
}

void main() {
  late _StubChildrenRepository repository;

  setUp(() {
    repository = _StubChildrenRepository();
  });

  Widget buildPicker({
    AddressMapPickerController? controller,
    ValueChanged<LatLng>? onPositionChanged,
    void Function(AddressSuggestion, AddressResolveSource)? onAddressResolved,
    ValueChanged<String>? onError,
  }) {
    return ProviderScope(
      overrides: [childrenRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: Scaffold(
          body: AddressMapPicker(
            controller: controller,
            cityBias: 'Curitiba, PR',
            onPositionChanged: onPositionChanged ?? (_) {},
            onAddressResolved: onAddressResolved ?? (_, _) {},
            onError: onError,
          ),
        ),
      ),
    );
  }

  testWidgets('autocomplete busca com debounce e seleção preenche callbacks', (
    tester,
  ) async {
    repository.autocompleteResults = const [
      AddressSuggestion(
        label: 'Rua Teste, 123 - Centro, Curitiba/PR',
        street: 'Rua Teste',
        number: '123',
        district: 'Centro',
        city: 'Curitiba',
        state: 'PR',
        latitude: -25.43,
        longitude: -49.27,
      ),
    ];

    LatLng? position;
    AddressSuggestion? resolved;
    AddressResolveSource? resolvedSource;
    await tester.pumpWidget(
      buildPicker(
        onPositionChanged: (p) => position = p,
        onAddressResolved: (s, source) {
          resolved = s;
          resolvedSource = source;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Buscar endereço...'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Rua Teste 123');
    // Debounce de 400ms antes de chamar o autocomplete.
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    expect(repository.autocompleteCalls, 1);
    expect(repository.lastAutocompleteText, 'Rua Teste 123');
    expect(repository.lastAutocompleteCity, 'Curitiba, PR');
    expect(find.text('Rua Teste, 123 - Centro, Curitiba/PR'), findsOneWidget);

    await tester.tap(find.text('Rua Teste, 123 - Centro, Curitiba/PR'));
    await tester.pumpAndSettle();

    expect(resolved?.city, 'Curitiba');
    expect(resolved?.state, 'PR');
    // Escolha explícita na busca: origem search (pode preencher tudo).
    expect(resolvedSource, AddressResolveSource.search);
    expect(position?.latitude, -25.43);
    expect(position?.longitude, -49.27);
    // A escolha na busca NÃO dispara reverse extra (o endereço já veio
    // estruturado do autocomplete).
    expect(repository.reverseCalls, 0);
  });

  testWidgets('mover o mapa dispara reverse com debounce e reporta endereço', (
    tester,
  ) async {
    LatLng? position;
    AddressSuggestion? resolved;
    AddressResolveSource? resolvedSource;
    await tester.pumpWidget(
      buildPicker(
        onPositionChanged: (p) => position = p,
        onAddressResolved: (s, source) {
          resolved = s;
          resolvedSource = source;
        },
      ),
    );
    await tester.pumpAndSettle();

    final mapCenter = tester.getCenter(find.byType(FlutterMap));
    await tester.dragFrom(
      mapCenter + const Offset(0, 120),
      const Offset(-70, -40),
    );
    await tester.pump();
    // Debounce de 500ms do reverse após parar de mover.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(repository.reverseCalls, 1);
    expect(position, isNotNull);
    expect(resolved?.label, 'Rua Nova, 50 - Centro, Curitiba/PR');
    // Reverse é efeito colateral do gesto: o consumidor só preenche vazios.
    expect(resolvedSource, AddressResolveSource.reverse);
    expect(find.text('Rua Nova, 50 - Centro, Curitiba/PR'), findsOneWidget);
  });

  testWidgets(
    'controller.moveTo (geocode forward) centraliza sem disparar reverse',
    (tester) async {
      final controller = AddressMapPickerController();
      LatLng? position;
      await tester.pumpWidget(
        buildPicker(
          controller: controller,
          onPositionChanged: (p) => position = p,
        ),
      );
      await tester.pumpAndSettle();

      controller.moveTo(
        const LatLng(-25.43, -49.27),
        label: 'Rua Digitada, 123 - Curitiba/PR',
      );
      await tester.pumpAndSettle();

      expect(position?.latitude, -25.43);
      expect(position?.longitude, -49.27);
      expect(find.text('Rua Digitada, 123 - Curitiba/PR'), findsOneWidget);
      // Movimento programático: não chama reverse nem gasta request.
      expect(repository.reverseCalls, 0);
    },
  );
}
