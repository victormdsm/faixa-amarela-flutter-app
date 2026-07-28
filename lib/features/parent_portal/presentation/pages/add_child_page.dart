import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/catalog_option.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/e2e_keys.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../../core/presentation/widgets/faixa_image_picker.dart';
import '../../../../core/presentation/widgets/faixa_section_card.dart';
import '../../../../domain/models/child.dart';
import '../../../../features/catalog/data/catalog_repository.dart';
import '../providers/parent_portal_providers.dart';
import '../state/add_child_controller.dart';
import '../widgets/address_map_picker.dart';

class AddChildPage extends ConsumerStatefulWidget {
  const AddChildPage({super.key, this.childToEdit});

  final Child? childToEdit;

  @override
  ConsumerState<AddChildPage> createState() => _AddChildPageState();
}

class _AddChildPageState extends ConsumerState<AddChildPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _cpfCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _numberCtrl;
  late final TextEditingController _complementCtrl;
  late final TextEditingController _zipCodeCtrl;

  final _picker = ImagePicker();
  CatalogOption? _shift;
  CatalogOption? _school;
  String? _photoLocalPath;

  // Mapa do endereço: marcador plotado pelo geocode (debounce de 800ms ao
  // digitar) e ajustável por arraste. Null = mapa escondido (geocode falhou
  // ou campos incompletos) e o cadastro segue sem coordenadas, como antes.
  Timer? _geocodeDebounce;
  int _geocodeSeq = 0;
  bool _geocoding = false;
  LatLng? _marker;
  String? _resolvedLabel;

  bool get _isEditing => widget.childToEdit != null;

  @override
  void initState() {
    super.initState();
    final c = widget.childToEdit;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _cpfCtrl = TextEditingController(text: c?.cpf ?? '');
    _streetCtrl = TextEditingController();
    _numberCtrl = TextEditingController();
    _complementCtrl = TextEditingController();
    _zipCodeCtrl = TextEditingController();

    if (_isEditing) {
      Future.microtask(() => _loadAddress());
    }

    _streetCtrl.addListener(_scheduleGeocode);
    _numberCtrl.addListener(_scheduleGeocode);
    _zipCodeCtrl.addListener(_scheduleGeocode);
  }

  void _scheduleGeocode() {
    // Invalida qualquer resposta ainda em voo: os campos mudaram.
    _geocodeSeq++;
    _geocodeDebounce?.cancel();
    final ready =
        _streetCtrl.text.trim().isNotEmpty &&
        _numberCtrl.text.trim().isNotEmpty &&
        _zipCodeCtrl.text.trim().length >= 8;
    if (!ready) {
      if (_marker != null || _geocoding) {
        setState(() {
          _marker = null;
          _resolvedLabel = null;
          _geocoding = false;
        });
      }
      return;
    }
    _geocodeDebounce = Timer(const Duration(milliseconds: 800), _runGeocode);
  }

  Future<void> _runGeocode() async {
    final seq = ++_geocodeSeq;
    final text =
        '${_streetCtrl.text.trim()}, ${_numberCtrl.text.trim()}, '
        '${_zipCodeCtrl.text.trim()}';
    setState(() => _geocoding = true);
    final result = await ref
        .read(childrenRepositoryProvider)
        .geocodeAddress(text);
    if (!mounted || seq != _geocodeSeq) return;
    setState(() {
      _geocoding = false;
      if (result == null) {
        _marker = null;
        _resolvedLabel = null;
      } else {
        _marker = LatLng(result.latitude, result.longitude);
        _resolvedLabel = result.label;
      }
    });
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
        _streetCtrl.text = (addr['street'] ?? '').toString();
        _numberCtrl.text = (addr['number'] ?? '').toString();
        _complementCtrl.text = (addr['reference'] ?? addr['complement'] ?? '')
            .toString();
        _zipCodeCtrl.text = (addr['zipcode'] ?? addr['zipCode'] ?? '')
            .toString();
        // Endereço já salvo com coordenadas: mostra o marcador direto, sem
        // esperar o debounce do geocode.
        final lat = (addr['latitude'] as num?)?.toDouble();
        final lng = (addr['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          setState(() => _marker = LatLng(lat, lng));
        }
      }
    } catch (_) {
      // Endereco nao e bloqueante para edicao dos dados pessoais.
    }
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _nameCtrl.dispose();
    _cpfCtrl.dispose();
    _streetCtrl.dispose();
    _numberCtrl.dispose();
    _complementCtrl.dispose();
    _zipCodeCtrl.dispose();
    super.dispose();
  }

  String? _validateCpf(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CPF e obrigatorio.';
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
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

  void _submit() {
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

    final formData = AddChildFormData(
      name: _nameCtrl.text.trim(),
      cpf: _cpfCtrl.text.trim(),
      schoolId: _school?.id ?? widget.childToEdit?.schoolId,
      shiftId: _shift?.id ?? widget.childToEdit?.shiftId,
      address: ChildAddress(
        street: _streetCtrl.text.trim(),
        number: _numberCtrl.text.trim(),
        complement: _complementCtrl.text.trim().isEmpty
            ? null
            : _complementCtrl.text.trim(),
        zipCode: _zipCodeCtrl.text.trim(),
        latitude: _marker?.latitude,
        longitude: _marker?.longitude,
      ),
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

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      appBar: FaixaAppBar.screen(
        title: _isEditing ? 'Editar dependente' : 'Novo dependente',
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
                  TextFormField(
                    key: E2EKeys.childCpfInput,
                    controller: _cpfCtrl,
                    decoration: const InputDecoration(
                      labelText: 'CPF',
                      hintText: 'Apenas numeros',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    textInputAction: TextInputAction.next,
                    validator: _validateCpf,
                    enabled: !_isEditing,
                  ),
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
                  if (_geocoding) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  if (_marker != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    AddressMapPicker(
                      position: _marker!,
                      onChanged: (p) => setState(() => _marker = p),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _resolvedLabel != null
                          ? 'Local aproximado: $_resolvedLabel. Arraste o marcador para ajustar.'
                          : 'Arraste o marcador para ajustar a localizacao.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (addState.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppInfoBanner(
                  message: addState.error.toString(),
                  icon: Icons.error_outline_rounded,
                  color: AppColors.danger,
                ),
              ),
            FilledButton(
              key: E2EKeys.childSaveButton,
              onPressed: addState.isLoading ? null : _submit,
              child: Text(
                addState.isLoading
                    ? 'Salvando...'
                    : (_isEditing
                          ? 'Salvar alteracoes'
                          : 'Cadastrar dependente'),
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
