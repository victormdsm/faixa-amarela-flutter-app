import 'package:app_faixa_amarela/core/models/catalog_option.dart';
import 'package:app_faixa_amarela/core/presentation/widgets/faixa_searchable_select.dart';
import 'package:app_faixa_amarela/domain/models/driver_profile.dart';
import 'package:app_faixa_amarela/domain/models/driver_profile_change_request.dart';
import 'package:app_faixa_amarela/domain/repositories/driver_repository.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_session.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/auth_user.dart';
import 'package:app_faixa_amarela/features/auth/domain/entities/user_role.dart';
import 'package:app_faixa_amarela/features/auth/presentation/state/app_session_controller.dart';
import 'package:app_faixa_amarela/features/auth/presentation/state/app_session_state.dart';
import 'package:app_faixa_amarela/features/catalog/data/catalog_repository.dart';
import 'package:app_faixa_amarela/features/driver_portal/data/driver_profile_storage.dart';
import 'package:app_faixa_amarela/features/driver_portal/data/nestjs_driver_profile_change_request_repository.dart';
import 'package:app_faixa_amarela/features/driver_portal/presentation/pages/driver_settings_page.dart';
import 'package:app_faixa_amarela/features/driver_portal/presentation/providers/driver_portal_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const _profileJson = <String, dynamic>{
    'id': 1,
    'userId': 1,
    'name': 'Tio Original',
    'cpf': '12345678900',
    'licenseNumber': '123456',
    'cnh': '123456',
    'cellPhone': '45999990000',
    'information': 'Info original',
    'email': 'tio@test.com',
    'avatarUrl': null,
    'van': {
      'id': 1,
      'plate': 'ABC1234',
      'model': 'Fiat Ducato',
      'color': 'Branca',
      'year': '2020',
      'imageUrl': null,
      'publicContactName': 'Contato Van',
      'publicContactPhone': '45988887777',
    },
    'schools': [
      {
        'id': 1,
        'name': 'Escola A',
        'shiftIds': [1],
      },
    ],
    'districts': [
      {
        'id': 10,
        'name': 'Bairro X',
        'shiftIds': [1],
      },
    ],
    'districtShiftMap': {
      '10': [1],
    },
  };

  final _session = AuthSession(
    accessToken: 'token',
    tokenType: 'Bearer',
    user: AuthUser(
      id: 1,
      name: 'Tio Original',
      email: 'tio@test.com',
      roles: const ['driver'],
    ),
  );

  ProviderScope _pumpSettingsPage(Widget child) {
    return ProviderScope(
      overrides: [
        appSessionControllerProvider.overrideWith(
          () => _FakeSessionController(session: _session),
        ),
        driverProfileStorageProvider.overrideWithValue(_FakeStorage()),
        driverProfileProvider.overrideWith(
          () => _FakeProfileController(profileJson: _profileJson),
        ),
        driverProfileRepositoryProvider.overrideWithValue(
          _FakeDriverRepository(profileJson: _profileJson),
        ),
        driverProfileChangeRequestRepositoryProvider.overrideWithValue(
          _FakeChangeRequestRepository(),
        ),
        driverProfileChangeRequestsProvider.overrideWith((ref) async => const []),
        schoolsCatalogProvider.overrideWith(
          (ref) async => const [
            CatalogOption(
              id: 1,
              name: 'Escola A',
              shifts: [CatalogOption(id: 1, name: 'Manhã')],
            ),
          ],
        ),
        districtsCatalogProvider.overrideWith(
          (ref) async => const [CatalogOption(id: 10, name: 'Bairro X')],
        ),
        shiftsCatalogProvider.overrideWith(
          (ref) async => const [
            CatalogOption(id: 1, name: 'Manhã'),
            CatalogOption(id: 2, name: 'Tarde'),
          ],
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  Future<void> _pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_pumpSettingsPage(const DriverSettingsPage()));
    await tester.pumpAndSettle();
  }

  group('DriverSettingsPage edit modes', () {
    testWidgets('personal and coverage fields start disabled', (tester) async {
      await _pumpPage(tester);

      final nameField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Nome'),
      );
      expect(nameField.enabled, isFalse);

      for (final label in [
        'Telefone / WhatsApp',
        'CNH',
        'Sobre / Informações adicionais',
      ]) {
        final field = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, label),
        );
        expect(field.enabled, isFalse, reason: label);
      }

      final publicContactName = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Nome de contato público (obrigatório)'),
      );
      expect(publicContactName.enabled, isFalse);

      final selects = find.byType(FaixaSearchableSelect<CatalogOption>);
      expect(selects, findsNWidgets(2));
      expect(tester.widget<FaixaSearchableSelect<CatalogOption>>(selects.at(0)).enabled, isFalse);
      expect(tester.widget<FaixaSearchableSelect<CatalogOption>>(selects.at(1)).enabled, isFalse);
    });

    testWidgets('tapping personal edit enables only personal fields',
        (tester) async {
      await _pumpPage(tester);

      await tester.tap(find.text('Editar dados pessoais'));
      await tester.pumpAndSettle();

      final nameField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Nome'),
      );
      expect(nameField.enabled, isTrue);

      for (final label in [
        'Telefone / WhatsApp',
        'CNH',
        'Sobre / Informações adicionais',
      ]) {
        final field = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, label),
        );
        expect(field.enabled, isTrue, reason: label);
      }

      // Coverage continua travada.
      final selects = find.byType(FaixaSearchableSelect<CatalogOption>);
      expect(tester.widget<FaixaSearchableSelect<CatalogOption>>(selects.at(0)).enabled, isFalse);
      expect(tester.widget<FaixaSearchableSelect<CatalogOption>>(selects.at(1)).enabled, isFalse);

      // Veículo e contato público continuam travados.
      final brandField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Marca / Modelo'),
      );
      expect(brandField.enabled, isFalse);

      final publicContactName = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Nome de contato público (obrigatório)'),
      );
      expect(publicContactName.enabled, isFalse);
    });

    testWidgets('tapping coverage edit enables only coverage selectors',
        (tester) async {
      await _pumpPage(tester);

      await tester.tap(find.text('Editar cobertura'));
      await tester.pumpAndSettle();

      final selects = find.byType(FaixaSearchableSelect<CatalogOption>);
      expect(tester.widget<FaixaSearchableSelect<CatalogOption>>(selects.at(0)).enabled, isTrue);
      expect(tester.widget<FaixaSearchableSelect<CatalogOption>>(selects.at(1)).enabled, isTrue);

      final nameField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Nome'),
      );
      expect(nameField.enabled, isFalse);

      final brandField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Marca / Modelo'),
      );
      expect(brandField.enabled, isFalse);
    });

    testWidgets('cancel personal edit restores original values', (tester) async {
      await _pumpPage(tester);

      await tester.tap(find.text('Editar dados pessoais'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'),
        'Novo Nome',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Telefone / WhatsApp'),
        '45111112222',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'CNH'),
        '654321',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Sobre / Informações adicionais'),
        'Nova info',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar edição'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Nome')).controller?.text,
        'Tio Original',
      );
      expect(
        tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Telefone / WhatsApp')).controller?.text,
        '45999990000',
      );
      expect(
        tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'CNH')).controller?.text,
        '123456',
      );
      expect(
        tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Sobre / Informações adicionais')).controller?.text,
        'Info original',
      );
    });

    testWidgets('cancel coverage edit restores original selection',
        (tester) async {
      await _pumpPage(tester);

      // Estado inicial: 1 escola e 1 bairro.
      expect(find.textContaining('1 escola(s) e 1 bairro(s)'), findsOneWidget);

      await tester.tap(find.text('Editar cobertura'));
      await tester.pumpAndSettle();

      // Remove o bairro selecionado.
      await tester.tap(find.text('Bairros atendidos'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      // Após remover: 1 escola e 0 bairros.
      expect(find.textContaining('1 escola(s) e 0 bairro(s)'), findsOneWidget);

      await tester.tap(find.text('Cancelar edição'));
      await tester.pumpAndSettle();

      // Cancelamento restaura a seleção original.
      expect(find.textContaining('1 escola(s) e 1 bairro(s)'), findsOneWidget);
    });

    testWidgets('save exits edit mode', (tester) async {
      await _pumpPage(tester);

      await tester.tap(find.text('Editar dados pessoais'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'),
        'Novo Nome',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar configurações'));
      await tester.pumpAndSettle();

      expect(find.text('Editar dados pessoais'), findsOneWidget);
      expect(find.text('Cancelar edição'), findsNothing);

      final nameField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Nome'),
      );
      expect(nameField.enabled, isFalse);
    });
  });
}

class _FakeSessionController extends AppSessionController {
  _FakeSessionController({required this.session});

  final AuthSession session;

  @override
  AppSessionState build() {
    return AppSessionState(
      session: session,
      isLoading: false,
      loginRole: UserRole.driver,
    );
  }
}

class _FakeStorage extends DriverProfileStorage {
  @override
  Map<String, dynamic>? load(int userId) => null;

  @override
  Future<void> save(int userId, Map<String, dynamic> profile) async {}

  @override
  Future<void> clear() async {}
}

class _FakeProfileController extends DriverProfileController {
  _FakeProfileController({required this.profileJson});

  final Map<String, dynamic> profileJson;

  @override
  Future<Map<String, dynamic>> build() async => profileJson;

  @override
  Future<void> refresh() async {}
}

class _FakeDriverRepository implements DriverRepository {
  _FakeDriverRepository({required this.profileJson});

  final Map<String, dynamic> profileJson;

  @override
  Future<DriverProfile?> getDriverProfile() async {
    return DriverProfile.fromJson(profileJson);
  }

  @override
  Future<DriverProfile> updateBasicProfile({
    required String name,
    String? cellPhone,
    String? information,
    String? cnh,
  }) async {
    final updated = Map<String, dynamic>.from(profileJson);
    updated['name'] = name;
    if (cellPhone != null) updated['cellPhone'] = cellPhone;
    if (information != null) updated['information'] = information;
    if (cnh != null) updated['cnh'] = cnh;
    return DriverProfile.fromJson(updated);
  }

  @override
  Future<void> updateVehiclePublicContact({
    String? publicContactName,
    String? publicContactPhone,
  }) async {}
}

class _FakeChangeRequestRepository
    extends NestjsDriverProfileChangeRequestRepository {
  _FakeChangeRequestRepository() : super(Dio());

  @override
  Future<String> uploadImage(String filePath, {required String type}) async {
    return '';
  }

  @override
  Future<Map<String, dynamic>> submitRequest({
    required List<int> schoolIds,
    required List<int>? districtIds,
    required Map<int, List<int>>? schoolShiftMap,
    required Map<int, List<int>>? districtShiftMap,
    String? avatarImagePath,
    String? vehicleImagePath,
    int? vehicleId,
    String? requestNote,
    String? requestedVehiclePlaca,
    String? requestedVehicleMarca,
    String? requestedVehicleCor,
    String? requestedVehicleAno,
    String? requestedPublicContactName,
    String? requestedPublicContactPhone,
  }) async {
    return const <String, dynamic>{};
  }

  @override
  Future<List<DriverProfileChangeRequest>> listMyRequests() async {
    return const [];
  }
}
