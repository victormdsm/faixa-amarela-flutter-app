import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/app_error_reporter.dart';
import '../../../../core/models/catalog_option.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/e2e_keys.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../../core/presentation/widgets/faixa_image_picker.dart';
import '../../../../core/presentation/widgets/faixa_section_card.dart';
import '../../../../domain/models/address_suggestion.dart';
import '../../../../domain/models/child.dart';
import '../../../../features/catalog/data/catalog_repository.dart';
import '../providers/parent_portal_providers.dart';
import '../state/add_child_controller.dart';
import '../widgets/address_map_picker.dart';
import '../widgets/city_state_fields.dart';

class AddChildPage extends ConsumerStatefulWidget {
  const AddChildPage({super.key, this.childToEdit});

  final Child? childToEdit;

  @override
  ConsumerState<AddChildPage> createState() => _AddChildPageState();
}

class _AddChildPageState extends ConsumerState<AddChildPage> {
  final _formKey = GlobalKey<FormState>();
  final _documentFieldKey = GlobalKey<FormFieldState<String>>(
    debugLabel: 'childDocument',
  );
  late final TextEditingController _nameCtrl;
  late final TextEditingController _documentCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _numberCtrl;
  late final TextEditingController _complementCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _zipCodeCtrl;

  final _picker = ImagePicker();
  CatalogOption? _shift;
  CatalogOption? _school;
  String? _photoLocalPath;

  // Documento: CPF (default) ou RG. RG exige UF emissora
  // ([_documentStateUf]); ao voltar para CPF a UF é descartada — o
  // backend rejeita `documentState` com CPF.
  String _documentType = ChildDocumentType.cpf;
  String? _documentStateUf;

  // Endereço: cidade/UF (obrigatórios) habilitam o mapa estilo Uber
  // (pin central + busca + GPS). [_marker] guarda as coordenadas
  // confirmadas; null quando o ponto nunca foi definido — nesse caso o
  // salvamento exige consentimento (o backend re-geocodifica).
  CatalogOption? _city;
  String? _stateUf;
  String? _pendingCityName;
  LatLng? _marker;
  String? _resolvedLabel;
  ChildAddress? _originalAddress;

  bool get _isEditing => widget.childToEdit != null;

  bool get _isRg => _documentType == ChildDocumentType.rg;

  String? get _cityBias {
    final city = _city;
    final uf = _stateUf;
    if (city == null || uf == null) return null;
    return '${city.name}, $uf';
  }

  @override
  void initState() {
    super.initState();
    final c = widget.childToEdit;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _documentCtrl = TextEditingController(text: c?.cpf ?? '');
    _documentType = ChildDocumentType.parse(c?.documentType);
    final docState = c?.documentState?.toUpperCase();
    _documentStateUf = docState != null && kBrazilStates.contains(docState)
        ? docState
        : null;
    _streetCtrl = TextEditingController();
    _numberCtrl = TextEditingController();
    _complementCtrl = TextEditingController();
    _districtCtrl = TextEditingController();
    _zipCodeCtrl = TextEditingController();

    if (_isEditing) {
      Future.microtask(() => _loadAddress());
    }
  }

  Future<void> _loadAddress() async {
    final c = widget.childToEdit;
    if (c == null) return;
    try {
      final repo = ref.read(childrenRepositoryProvider);
      final addresses = await repo.getChildAddresses(c.id);
      if (addresses.isNotEmpty && mounted) {
        bool isDefault(Map<String, dynamic> a) {
          final raw = a['isDefault'] ?? a['is_default'];
          return raw == true || raw == 1;
        }

        final addr = addresses.firstWhere(
          isDefault,
          orElse: () => addresses.first,
        );
        final street = (addr['street'] ?? '').toString();
        final number = (addr['number'] ?? '').toString();
        final complement = (addr['reference'] ?? addr['complement'] ?? '')
            .toString();
        final district = (addr['neighborhood'] ?? addr['district'] ?? '')
            .toString();
        final zipcode = (addr['zipcode'] ?? addr['zipCode'] ?? '').toString();
        final city = (addr['city'] ?? '').toString();
        final state = (addr['state'] ?? '').toString().toUpperCase();
        final lat = (addr['latitude'] as num?)?.toDouble();
        final lng = (addr['longitude'] as num?)?.toDouble();

        setState(() {
          _streetCtrl.text = street;
          _numberCtrl.text = number;
          _complementCtrl.text = complement;
          _districtCtrl.text = district;
          _zipCodeCtrl.text = zipcode;
          _pendingCityName = city.trim().isEmpty ? null : city.trim();
          _stateUf = kBrazilStates.contains(state) ? state : null;
          // Endereço já salvo com coordenadas: mostra o pin direto.
          if (lat != null && lng != null) {
            _marker = LatLng(lat, lng);
            _resolvedLabel = _composeLabel(
              street: street,
              number: number,
              district: district,
              city: city,
              state: state,
            );
          }
          _originalAddress = ChildAddress(
            street: street,
            number: number,
            complement: complement.trim().isEmpty ? null : complement.trim(),
            zipCode: zipcode,
            district: district.trim().isEmpty ? null : district.trim(),
            city: city.trim().isEmpty ? null : city.trim(),
            state: kBrazilStates.contains(state) ? state : null,
            latitude: lat,
            longitude: lng,
          );
        });
      }
    } catch (_) {
      // Endereco nao e bloqueante para edicao dos dados pessoais.
    }
  }

  static String _composeLabel({
    required String street,
    required String number,
    required String district,
    required String city,
    required String state,
  }) {
    final parts = <String>[
      if (street.trim().isNotEmpty)
        number.trim().isNotEmpty ? '$street, $number' : street,
      if (district.trim().isNotEmpty) district,
      if (city.trim().isNotEmpty)
        state.trim().isNotEmpty ? '$city/$state' : city,
    ];
    final label = parts.join(' - ').trim();
    return label.isEmpty ? 'Endereço salvo' : label;
  }

  /// Preenche os campos com o endereço resolvido pelo mapa (reverse ou
  /// autocomplete). Só sobrescreve o que veio preenchido — nunca apaga
  /// algo que o pai digitou.
  void _applySuggestion(AddressSuggestion suggestion) {
    setState(() {
      _resolvedLabel = suggestion.label;
      if ((suggestion.street ?? '').isNotEmpty) {
        _streetCtrl.text = suggestion.street!;
      }
      if ((suggestion.number ?? '').isNotEmpty) {
        _numberCtrl.text = suggestion.number!;
      }
      if ((suggestion.district ?? '').isNotEmpty) {
        _districtCtrl.text = suggestion.district!;
      }
      final uf = suggestion.state?.toUpperCase();
      if (uf != null && kBrazilStates.contains(uf)) {
        _stateUf = uf;
      }
      final cityName = suggestion.city;
      if (cityName != null && cityName.trim().isNotEmpty) {
        final cities = ref.read(citiesCatalogProvider).value ?? const [];
        final query = cityName.trim().toLowerCase();
        for (final c in cities) {
          if (c.name.trim().toLowerCase() == query) {
            _city = c;
            break;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _documentCtrl.dispose();
    _streetCtrl.dispose();
    _numberCtrl.dispose();
    _complementCtrl.dispose();
    _districtCtrl.dispose();
    _zipCodeCtrl.dispose();
    super.dispose();
  }

  /// Troca CPF ↔ RG: limpa o número (muda máscara/validação) e descarta a
  /// UF ao voltar para CPF. O [reset] no campo remove erros de validação
  /// exibidos antes da troca.
  void _onDocumentTypeChanged(String type) {
    if (type == _documentType) return;
    setState(() {
      _documentType = type;
      _documentCtrl.clear();
      _documentFieldKey.currentState?.reset();
      if (type == ChildDocumentType.cpf) _documentStateUf = null;
    });
  }

  String? _validateDocument(String? value) {
    final text = value?.trim() ?? '';
    if (_documentType == ChildDocumentType.rg) {
      if (text.isEmpty) {
        return 'RG e obrigatorio.';
      }
      if (text.length < 5 || text.length > 14) {
        return 'RG deve ter entre 5 e 14 caracteres.';
      }
      return null;
    }
    if (text.isEmpty) {
      return 'CPF e obrigatorio.';
    }
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 11) {
      return 'CPF deve ter 11 digitos.';
    }
    return null;
  }

  static const _maxPhotoBytes = 5 * 1024 * 1024; // 5 MB

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      maxHeight: 900,
      imageQuality: 75,
    );
    if (file == null || !mounted) return;

    final bytes = await file.length();
    if (!mounted) return;
    if (bytes > _maxPhotoBytes) {
      showAppSnackBar(
        context,
        message: 'A foto deve ter no maximo 5 MB. Escolha outra imagem.',
        type: AppFeedbackType.warning,
      );
      return;
    }

    setState(() => _photoLocalPath = file.path);
  }

  /// Salvar sem coordenadas só com consentimento: o backend re-geocodifica
  /// o endereço automaticamente depois.
  Future<bool> _confirmSaveWithoutCoordinates() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        title: const Text('Endereco fora do mapa'),
        content: const Text(
          'Nao conseguimos localizar esse endereco no mapa. Salvar assim '
          'mesmo? Vamos tentar localiza-lo automaticamente depois.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Salvar assim mesmo'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_shift == null && !_isEditing) {
      showAppSnackBar(
        context,
        message: 'Selecione o turno.',
        type: AppFeedbackType.warning,
      );
      return;
    }
    if (_school == null && !_isEditing) {
      showAppSnackBar(
        context,
        message: 'Selecione a escola.',
        type: AppFeedbackType.warning,
      );
      return;
    }

    if (_marker == null) {
      final confirmed = await _confirmSaveWithoutCoordinates();
      if (!confirmed || !mounted) return;
    }

    final formData = AddChildFormData(
      name: _nameCtrl.text.trim(),
      document: _documentCtrl.text.trim(),
      documentType: _documentType,
      documentState: _documentType == ChildDocumentType.rg
          ? _documentStateUf
          : null,
      schoolId: _school?.id ?? widget.childToEdit?.schoolId,
      shiftId: _shift?.id ?? widget.childToEdit?.shiftId,
      address: ChildAddress(
        street: _streetCtrl.text.trim(),
        number: _numberCtrl.text.trim(),
        complement: _complementCtrl.text.trim().isEmpty
            ? null
            : _complementCtrl.text.trim(),
        zipCode: _zipCodeCtrl.text.trim(),
        district: _districtCtrl.text.trim().isEmpty
            ? null
            : _districtCtrl.text.trim(),
        city: _city?.name,
        state: _stateUf,
        latitude: _marker?.latitude,
        longitude: _marker?.longitude,
      ),
      originalAddress: _originalAddress,
      photoLocalPath: _photoLocalPath,
    );

    final controller = ref.read(addChildControllerProvider.notifier);
    final future = _isEditing
        ? controller.updateChild(widget.childToEdit!.id, formData)
        : controller.submit(formData);

    future.then((_) async {
      if (!mounted) return;
      final state = ref.read(addChildControllerProvider);
      if (!state.hasError) {
        await ref.read(childrenControllerProvider.notifier).refresh();
        if (!mounted) return;
        context.pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shiftsAsync = ref.watch(shiftsCatalogProvider);
    final schoolsAsync = ref.watch(schoolsCatalogProvider);
    final citiesAsync = ref.watch(citiesCatalogProvider);
    final addState = ref.watch(addChildControllerProvider);

    // Auto-select shift/school when editing and catalog loads
    if (_isEditing && _shift == null && shiftsAsync.hasValue) {
      final shifts = shiftsAsync.value ?? const [];
      final editShiftId = widget.childToEdit!.shiftId;
      for (final s in shifts) {
        if (s.id == editShiftId) {
          _shift = s;
          break;
        }
      }
    }
    if (_isEditing && _school == null && schoolsAsync.hasValue) {
      final schools = schoolsAsync.value ?? const [];
      final editSchoolId = widget.childToEdit!.schoolId;
      for (final s in schools) {
        if (s.id == editSchoolId) {
          _school = s;
          break;
        }
      }
    }
    // Auto-select cidade quando o catálogo carrega (edição).
    final pendingCity = _pendingCityName;
    if (_city == null && pendingCity != null && citiesAsync.hasValue) {
      final cities = citiesAsync.value ?? const [];
      final query = pendingCity.toLowerCase();
      for (final c in cities) {
        if (c.name.trim().toLowerCase() == query) {
          _city = c;
          _pendingCityName = null;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      appBar: FaixaAppBar.screen(
        title: _isEditing ? 'Editar dependente' : 'Novo dependente',
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        // Mesmo padrão do driver_settings: alguns aparelhos (MIUI/gesture
        // bar custom) reportam inset bottom 0 — o piso garante respiro.
        minimum: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: FilledButton(
            key: E2EKeys.childSaveButton,
            onPressed: addState.isLoading ? null : _submit,
            child: addState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isEditing ? 'Salvar alteracoes' : 'Cadastrar dependente',
                  ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            FaixaSectionCard(
              title: 'Dados pessoais',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: FaixaImagePicker.child(
                      imageUrl: widget.childToEdit?.photoUrl,
                      localPath: _photoLocalPath,
                      onTap: _pickPhoto,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    key: E2EKeys.childNameInput,
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome completo',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Nome e obrigatorio.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: ChildDocumentType.cpf,
                          label: Text('CPF'),
                          icon: Icon(Icons.badge_outlined),
                        ),
                        ButtonSegment<String>(
                          value: ChildDocumentType.rg,
                          label: Text('RG'),
                          icon: Icon(Icons.contact_page_outlined),
                        ),
                      ],
                      selected: {_documentType},
                      // Documento é imutável na edição — o seletor acompanha
                      // o campo (desabilitado), exibindo o tipo carregado.
                      onSelectionChanged: _isEditing
                          ? null
                          : (selection) =>
                                _onDocumentTypeChanged(selection.first),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // A KeyedSubtree preserva a E2E key histórica (o campo do
                  // documento usa GlobalKey própria para reset na troca de
                  // tipo).
                  KeyedSubtree(
                    key: E2EKeys.childCpfInput,
                    child: TextFormField(
                      key: _documentFieldKey,
                      controller: _documentCtrl,
                      decoration: InputDecoration(
                        labelText: _isRg ? 'RG da criança' : 'CPF da criança',
                        hintText: _isRg
                            ? 'Como consta no documento'
                            : 'Apenas numeros',
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      keyboardType: _isRg
                          ? TextInputType.text
                          : TextInputType.number,
                      textCapitalization: _isRg
                          ? TextCapitalization.characters
                          : TextCapitalization.none,
                      inputFormatters: _isRg
                          ? [LengthLimitingTextInputFormatter(14)]
                          : [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                      textInputAction: TextInputAction.next,
                      validator: _validateDocument,
                      enabled: !_isEditing,
                    ),
                  ),
                  if (_isRg) ...[
                    const SizedBox(height: AppSpacing.md),
                    UfSelectField(
                      key: E2EKeys.childDocumentUfSelect,
                      value: _documentStateUf,
                      enabled: !_isEditing,
                      onChanged: (v) => setState(() => _documentStateUf = v),
                      validator: (v) =>
                          v == null ? 'Selecione a UF do RG.' : null,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _CatalogDropdown(
                    key: E2EKeys.childSchoolDropdown,
                    label: 'Escola',
                    asyncValue: schoolsAsync,
                    value: _school,
                    onChanged: (v) => setState(() => _school = v),
                    validator: (v) =>
                        v == null ? 'Selecione uma escola.' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _CatalogDropdown(
                    key: E2EKeys.childShiftDropdown,
                    label: 'Turno',
                    asyncValue: shiftsAsync,
                    value: _shift,
                    onChanged: (v) => setState(() => _shift = v),
                    validator: (v) => v == null ? 'Selecione um turno.' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FaixaSectionCard(
              title: _isEditing ? 'Endereco padrao' : 'Endereco',
              subtitle: _isEditing
                  ? 'Para gerenciar varios enderecos, use a tela de detalhes do dependente.'
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CitySelectField(
                          citiesAsync: citiesAsync,
                          value: _city,
                          onChanged: (v) => setState(() => _city = v),
                          onRetry: () => ref.invalidate(citiesCatalogProvider),
                          validator: (v) =>
                              v == null ? 'Selecione a cidade.' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      SizedBox(
                        width: 118,
                        child: UfSelectField(
                          value: _stateUf,
                          onChanged: (v) => setState(() => _stateUf = v),
                          validator: (v) => v == null ? 'Selecione.' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_cityBias == null)
                    const AppInfoBanner(
                      message:
                          'Selecione cidade e UF para localizar o endereco no mapa.',
                      icon: Icons.map_outlined,
                      color: AppColors.slate,
                    )
                  else
                    AddressMapPicker(
                      cityBias: _cityBias,
                      initialPosition: _marker,
                      initialLabel: _resolvedLabel,
                      onPositionChanged: (p) => setState(() => _marker = p),
                      onAddressResolved: _applySuggestion,
                      onError: (message) => showAppSnackBar(
                        context,
                        message: message,
                        type: AppFeedbackType.error,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: E2EKeys.addressStreetInput,
                    controller: _streetCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Rua',
                      prefixIcon: Icon(Icons.signpost_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Rua e obrigatoria.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: E2EKeys.addressNumberInput,
                    controller: _numberCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Numero',
                      prefixIcon: Icon(Icons.numbers_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Numero e obrigatorio.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: E2EKeys.addressComplementInput,
                    controller: _complementCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Complemento (opcional)',
                      prefixIcon: Icon(Icons.apartment_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _districtCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Bairro (opcional)',
                      prefixIcon: Icon(Icons.holiday_village_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: E2EKeys.addressZipCodeInput,
                    controller: _zipCodeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'CEP',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'CEP e obrigatorio.'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (addState.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppInfoBanner(
                  message: AppErrorReporter.messageFor(addState.error!),
                  icon: Icons.error_outline_rounded,
                  color: AppColors.danger,
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _CatalogDropdown extends StatelessWidget {
  const _CatalogDropdown({
    super.key,
    required this.label,
    required this.asyncValue,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final AsyncValue<List<CatalogOption>> asyncValue;
  final CatalogOption? value;
  final ValueChanged<CatalogOption?> onChanged;
  final String? Function(CatalogOption?)? validator;

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      loading: () => const InputDecorator(
        decoration: InputDecoration(labelText: 'Carregando...'),
        child: SizedBox(height: 20, child: LinearProgressIndicator()),
      ),
      error: (_, _) => DropdownButtonFormField<CatalogOption>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          errorText: 'Erro ao carregar $label.',
        ),
        items: const [],
        onChanged: onChanged,
        validator: validator,
      ),
      data: (items) => DropdownButtonFormField<CatalogOption>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: items
            .map(
              (s) => DropdownMenuItem(
                value: s,
                child: Text(s.name, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(growable: false),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}
