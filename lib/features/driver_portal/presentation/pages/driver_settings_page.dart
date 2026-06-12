import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/catalog_option.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../domain/models/driver_profile.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../../catalog/data/catalog_repository.dart';
import '../providers/driver_portal_providers.dart';

class DriverSettingsPage extends ConsumerStatefulWidget {
  const DriverSettingsPage({super.key});

  @override
  ConsumerState<DriverSettingsPage> createState() => _DriverSettingsPageState();
}

class _DriverSettingsPageState extends ConsumerState<DriverSettingsPage> {
  static const _maxUploadBytes =
      900 * 1024; // ~900KB para evitar 413 comum em Nginx.
  static const List<CatalogOption> _fallbackShiftOptions = [
    CatalogOption(id: 1, name: 'Manha'),
    CatalogOption(id: 2, name: 'Tarde'),
    CatalogOption(id: 3, name: 'Noite'),
    CatalogOption(id: 4, name: 'Integral'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _infoController = TextEditingController();
  final _cnhController = TextEditingController();
  final _vehicleBrandController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _picker = ImagePicker();

  bool _hydrated = false;
  bool _isSaving = false;
  bool _vehicleEditMode = false;
  String? _avatarImageUrl;
  String? _avatarImageLocalPath;
  String? _vehicleImageUrl;
  String? _vehicleImageLocalPath;
  String? _email;
  String? _cpf;
  Map<String, dynamic>? _coverageChangeRequest;
  List<Map<String, dynamic>> _coverageChangeRequestsRecent =
      const <Map<String, dynamic>>[];
  final Set<int> _selectedSchoolIds = <int>{};
  final Map<int, Set<int>> _districtShiftMap = <int, Set<int>>{};
  Set<int> _originalSelectedSchoolIds = <int>{};
  Map<int, Set<int>> _originalDistrictShiftMap = <int, Set<int>>{};
  // ignore: unused_field
  String? _originalAvatarImageUrl;
  // ignore: unused_field
  String? _originalVehicleImageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _infoController.dispose();
    _cnhController.dispose();
    _vehicleBrandController.dispose();
    _vehicleColorController.dispose();
    _vehicleYearController.dispose();
    _vehiclePlateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(driverProfileProvider);
    final session = ref.watch(appSessionControllerProvider).session;
    final isAdminAppUser = session?.user.isAdmin ?? false;
    final schoolsAsync = ref.watch(schoolsCatalogProvider);
    final districtsAsync = ref.watch(districtsCatalogProvider);
    final shiftsAsync = ref.watch(shiftsCatalogProvider);
    final shiftOptions = (shiftsAsync.value ?? const <CatalogOption>[])
        .where((e) => e.id > 0)
        .toList(growable: false);
    final effectiveShiftOptions = shiftOptions.isEmpty
        ? _fallbackShiftOptions
        : shiftOptions;

    ref.listen(driverProfileProvider, (previous, next) {
      next.whenData((data) {
        if (!_hydrated) {
          _applyProfile(data);
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuracoes'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _isSaving
                ? null
                : () {
                    setState(() => _hydrated = false);
                    ref.invalidate(driverProfileProvider);
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      bottomNavigationBar: profileAsync.maybeWhen(
        data: (_) => SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : () => _save(context),
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Salvando...' : 'Salvar configuracoes'),
            ),
          ),
        ),
        orElse: () => null,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorPane(message: error.toString()),
        data: (_) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              _SettingsHero(
                name: _nameController.text.trim().isEmpty
                    ? 'Tio da van'
                    : _nameController.text.trim(),
                subtitle: _vehiclePlateController.text.trim().isEmpty
                    ? 'Perfil, atendimento e veiculo'
                    : 'Veiculo ${_vehiclePlateController.text.trim().toUpperCase()}',
                avatarUrl: _avatarImageUrl,
                avatarLocalPath: _avatarImageLocalPath,
              ),
              const SizedBox(height: 12),
              _SettingsSection(
                icon: Icons.account_circle_outlined,
                title: 'Perfil do tio da van',
                subtitle: 'Dados de contato, foto e informacoes publicas.',
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileImagePreview(
                        imageUrl: _avatarImageUrl,
                        localPath: _avatarImageLocalPath,
                        onTap: _isSaving ? null : _pickAvatarImage,
                      ),
                      if (_avatarImageLocalPath != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _isSaving
                              ? null
                              : () => setState(
                                  () => _avatarImageLocalPath = null,
                                ),
                          icon: const Icon(Icons.undo_rounded),
                          label: const Text('Desfazer foto de perfil'),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Informe o nome.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        enabled: !_isSaving && isAdminAppUser,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: const Icon(Icons.mail_outline_rounded),
                          helperText: isAdminAppUser
                              ? 'Admin pode atualizar o e-mail de acesso.'
                              : null,
                        ),
                        validator: (value) {
                          if (!isAdminAppUser) return null;
                          final email = (value ?? '').trim();
                          if (email.isEmpty) return 'Informe o e-mail.';
                          final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!regex.hasMatch(email)) {
                            return 'Informe um e-mail valido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: ValueKey('cpf-${_cpf ?? ''}'),
                        initialValue: _cpf ?? '',
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'CPF',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Telefone / WhatsApp',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      if (isAdminAppUser) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_isSaving,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Nova senha (opcional)',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordConfirmController,
                          enabled: !_isSaving,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirmar nova senha',
                            prefixIcon: Icon(Icons.lock_reset_outlined),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _cnhController,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(
                          labelText: 'CNH',
                          prefixIcon: Icon(Icons.credit_card_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _infoController,
                        enabled: !_isSaving,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Sobre / Informacoes',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.info_outline_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SettingsSection(
                icon: Icons.directions_bus_filled_outlined,
                title: 'Veiculo',
                subtitle: 'Foto, modelo, cor, ano e placa usados no app.',
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Edit toggle row
                      Row(
                        children: [
                          const Spacer(),
                          if (!_vehicleEditMode)
                            TextButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : () =>
                                        setState(() => _vehicleEditMode = true),
                              icon: const Icon(Icons.edit_rounded, size: 16),
                              label: const Text('Editar dados do veiculo'),
                            )
                          else
                            TextButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : () => setState(
                                      () => _vehicleEditMode = false,
                                    ),
                              icon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 16,
                              ),
                              label: const Text('Cancelar edicao'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.slate,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _VehicleImagePreview(
                        imageUrl: _vehicleImageUrl,
                        localPath: _vehicleImageLocalPath,
                        onTap: (_isSaving || !_vehicleEditMode)
                            ? null
                            : _pickVehicleImage,
                      ),
                      if (!_vehicleEditMode) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 14,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Toque em "Editar dados" para alterar',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ],
                      if (_vehicleImageLocalPath != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _isSaving
                              ? null
                              : () => setState(
                                  () => _vehicleImageLocalPath = null,
                                ),
                          icon: const Icon(Icons.undo_rounded),
                          label: const Text('Desfazer foto do veiculo'),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _vehicleBrandController,
                        enabled: !_isSaving && _vehicleEditMode,
                        readOnly: !_vehicleEditMode,
                        decoration: const InputDecoration(
                          labelText: 'Marca / Modelo',
                          prefixIcon: Icon(Icons.directions_bus_outlined),
                        ),
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Informe a marca/modelo.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _vehicleColorController,
                              enabled: !_isSaving && _vehicleEditMode,
                              readOnly: !_vehicleEditMode,
                              decoration: const InputDecoration(
                                labelText: 'Cor',
                                prefixIcon: Icon(Icons.palette_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _vehicleYearController,
                              enabled: !_isSaving && _vehicleEditMode,
                              readOnly: !_vehicleEditMode,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Ano',
                                prefixIcon: Icon(Icons.calendar_today_outlined),
                              ),
                              validator: (v) {
                                final year = int.tryParse(v ?? '');
                                final currentYear =
                                    DateTime.now().year + 1;
                                if (year == null ||
                                    year < 1900 ||
                                    year > currentYear) {
                                  return 'Ano invalido.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _vehiclePlateController,
                        enabled: !_isSaving && _vehicleEditMode,
                        readOnly: !_vehicleEditMode,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Placa',
                          prefixIcon: Icon(Icons.pin_outlined),
                        ),
                        validator: (v) {
                          final plate = (v ?? '').trim();
                          if (plate.length < 3) return 'Placa invalida.';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SettingsSection(
                icon: Icons.map_outlined,
                title: 'Atendimento',
                subtitle: 'Escolas, bairros e periodos atendidos.',
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CoverageStatusBanner(
                        pendingRequest: _coverageChangeRequest,
                        schoolsCount: _selectedSchoolIds.length,
                        districtsCount: _districtShiftMap.length,
                      ),
                      if (_coverageChangeRequestsRecent.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _CoverageRecentRequestsCard(
                          items: _coverageChangeRequestsRecent,
                        ),
                      ],
                      const SizedBox(height: 16),
                      _CoveragePickerRow(
                        icon: Icons.school_rounded,
                        label: 'Escolas atendidas',
                        count: _selectedSchoolIds.length,
                        enabled: !_isSaving && schoolsAsync.hasValue,
                        onTap: schoolsAsync.hasValue
                            ? () => _pickMultiCatalog(
                                context,
                                title: 'Escolas atendidas',
                                options: schoolsAsync.value!,
                                selectedIds: _selectedSchoolIds,
                                onChanged: (value) => setState(() {
                                  _selectedSchoolIds
                                    ..clear()
                                    ..addAll(value);
                                }),
                              )
                            : null,
                      ),
                      if (schoolsAsync.hasValue &&
                          _selectedSchoolIds.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _CoverageChips(
                          options: schoolsAsync.value!,
                          selectedIds: _selectedSchoolIds,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _CoveragePickerRow(
                        icon: Icons.location_city_rounded,
                        label: 'Bairros atendidos',
                        count: _districtShiftMap.length,
                        enabled: !_isSaving && districtsAsync.hasValue,
                        onTap: districtsAsync.hasValue
                            ? () => _pickMultiCatalog(
                                context,
                                title: 'Bairros atendidos',
                                options: districtsAsync.value!,
                                selectedIds: _districtShiftMap.keys.toSet(),
                                onChanged: (value) => setState(() {
                                  final keep = value.toSet();
                                  _districtShiftMap.removeWhere(
                                    (key, value) => !keep.contains(key),
                                  );
                                  for (final id in keep) {
                                    _districtShiftMap.putIfAbsent(
                                      id,
                                      () => <int>{},
                                    );
                                  }
                                }),
                              )
                            : null,
                      ),
                      if (districtsAsync.hasValue &&
                          _districtShiftMap.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _DistrictShiftEditor(
                          districtOptions: districtsAsync.value!,
                          shiftOptions: effectiveShiftOptions,
                          districtShiftMap: _districtShiftMap,
                          enabled: !_isSaving,
                          onToggleShift: (districtId, shiftId) {
                            setState(() {
                              final set = _districtShiftMap.putIfAbsent(
                                districtId,
                                () => <int>{},
                              );
                              if (!set.add(shiftId)) {
                                set.remove(shiftId);
                              }
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyProfile(Map<String, dynamic> data) {
    _hydrated = true;
    _vehicleEditMode = false;
    _email = data['email']?.toString();
    _cpf = data['cpf']?.toString();
    _nameController.text = (data['name'] ?? '').toString();
    _emailController.text = (_email ?? '');
    _phoneController.text = (data['cell_phone'] ?? '').toString();
    _passwordController.clear();
    _passwordConfirmController.clear();
    _infoController.text = (data['information'] ?? '').toString();
    _cnhController.text = (data['cnh'] ?? '').toString();
    _avatarImageUrl = data['avatar_url']?.toString();
    _avatarImageLocalPath = null;
    _coverageChangeRequest = _map(data['coverage_change_request']);
    if (_coverageChangeRequest != null && _coverageChangeRequest!.isEmpty) {
      _coverageChangeRequest = null;
    }
    _coverageChangeRequestsRecent = _listOfMaps(
      data['coverage_change_requests_recent'],
    );

    final vehicle = _map(data['vehicle']);
    _vehicleBrandController.text = (vehicle['brand'] ?? '').toString();
    _vehicleColorController.text = (vehicle['color'] ?? '').toString();
    _vehicleYearController.text = (vehicle['year'] ?? '').toString();
    _vehiclePlateController.text = (vehicle['license_plate'] ?? '').toString();
    _vehicleImageUrl = vehicle['image_url']?.toString();
    _vehicleImageLocalPath = null;

    _selectedSchoolIds
      ..clear()
      ..addAll(
        _listOfMaps(
          data['schools'],
        ).map((e) => (e['id'] as num?)?.toInt() ?? 0).where((id) => id > 0),
      );

    _districtShiftMap.clear();
    for (final district in _listOfMaps(data['districts'])) {
      final districtId = (district['id'] as num?)?.toInt() ?? 0;
      if (districtId <= 0) continue;
      final shifts = ((district['shift_ids'] as List?) ?? const [])
          .map((e) => (e as num?)?.toInt() ?? 0)
          .where((id) => id > 0)
          .toSet();
      _districtShiftMap[districtId] = shifts;
    }

    _originalSelectedSchoolIds = Set<int>.from(_selectedSchoolIds);
    _originalDistrictShiftMap = <int, Set<int>>{
      for (final entry in _districtShiftMap.entries)
        entry.key: Set<int>.from(entry.value),
    };
    _originalAvatarImageUrl = _avatarImageUrl;
    _originalVehicleImageUrl = _vehicleImageUrl;

    if (mounted) setState(() {});
  }

  Future<void> _pickVehicleImage() async {
    await _pickImage(
      isAvatar: false,
      imageQuality: 62,
      maxWidth: 1280,
      maxHeight: 1280,
    );
  }

  Future<void> _pickAvatarImage() async {
    await _pickImage(
      isAvatar: true,
      imageQuality: 58,
      maxWidth: 900,
      maxHeight: 900,
    );
  }

  Future<void> _pickImage({
    required bool isAvatar,
    required int imageQuality,
    required double maxWidth,
    required double maxHeight,
  }) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    if (file == null || !mounted) return;

    final bytes = await file.length();
    if (!mounted) return;

    if (bytes > _maxUploadBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A foto selecionada ainda ficou grande para envio. Escolha outra foto menor.',
          ),
        ),
      );
      return;
    }

    setState(() {
      if (isAvatar) {
        _avatarImageLocalPath = file.path;
      } else {
        _vehicleImageLocalPath = file.path;
      }
    });
  }

  bool _hasCoverageChanges() {
    if (!const SetEquality<int>().equals(
      _selectedSchoolIds,
      _originalSelectedSchoolIds,
    )) {
      return true;
    }
    if (_districtShiftMap.length != _originalDistrictShiftMap.length) {
      return true;
    }
    for (final entry in _districtShiftMap.entries) {
      final original = _originalDistrictShiftMap[entry.key];
      if (original == null) return true;
      if (!const SetEquality<int>().equals(entry.value, original)) return true;
    }
    if (_avatarImageLocalPath != null) return true;
    if (_vehicleImageLocalPath != null) return true;
    return false;
  }

  Future<void> _save(BuildContext context) async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    final messenger = ScaffoldMessenger.of(context);

    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sessao expirada. Entre novamente.')),
      );
      return;
    }

    final isAdminAppUser = session.user.isAdmin;
    final newPassword = _passwordController.text.trim();
    final confirmPassword = _passwordConfirmController.text.trim();
    if (isAdminAppUser &&
        (newPassword.isNotEmpty || confirmPassword.isNotEmpty)) {
      if (newPassword.length < 6) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('A nova senha deve ter pelo menos 6 caracteres.'),
          ),
        );
        return;
      }
      if (newPassword != confirmPassword) {
        messenger.showSnackBar(
          const SnackBar(content: Text('A confirmacao de senha nao confere.')),
        );
        return;
      }
    }

    final hasCoverageChanges = _hasCoverageChanges();

    setState(() => _isSaving = true);
    DriverProfile? updatedProfile;
    try {
      bool coverageRequestSubmitted = false;

      // 1. Se houver mudancas de cobertura/imagens, submeter solicitacao no NestJS
      if (hasCoverageChanges) {
        final repo = ref.read(driverProfileChangeRequestRepositoryProvider);
        String? avatarUrl;
        String? vehicleImageUrl;
        if (_avatarImageLocalPath != null) {
          avatarUrl = await repo.uploadImage(_avatarImageLocalPath!);
        }
        if (_vehicleImageLocalPath != null) {
          vehicleImageUrl = await repo.uploadImage(_vehicleImageLocalPath!);
        }
        await repo.submitRequest(
          schoolIds: _selectedSchoolIds.toList()..sort(),
          districtShiftMap: {
            for (final entry in _districtShiftMap.entries)
              entry.key: (entry.value.toList()..sort()),
          },
          avatarImagePath: avatarUrl,
          vehicleImagePath: vehicleImageUrl,
          requestNote: null,
        );
        coverageRequestSubmitted = true;
      }

      // 2. Salvar dados basicos via endpoint canônico NestJS.
      updatedProfile = await ref
          .read(driverProfileRepositoryProvider)
          .updateBasicProfile(
            name: _nameController.text.trim(),
            email: isAdminAppUser ? _emailController.text.trim() : null,
            cellPhone: _phoneController.text.trim(),
            information: _infoController.text.trim(),
            cnh: _cnhController.text.trim(),
          );

      _applyProfile(updatedProfile.toJson());
      ref.invalidate(driverProfileProvider);

      if (context.mounted) {
        if (coverageRequestSubmitted) {
          showAppSnackBar(
            context,
            message:
                'Perfil atualizado. As alteracoes que precisam de aprovacao foram enviadas ao admin.',
            type: AppFeedbackType.warning,
          );
        } else {
          showAppSnackBar(
            context,
            message: 'Configuracoes atualizadas com sucesso.',
            type: AppFeedbackType.success,
          );
        }
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(context, message: e.message, type: AppFeedbackType.error);
    } catch (_) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        message: 'Falha ao salvar configuracoes.',
        type: AppFeedbackType.error,
      );
    } finally {
      if (context.mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickMultiCatalog(
    BuildContext context, {
    required String title,
    required List<CatalogOption> options,
    required Set<int> selectedIds,
    required ValueChanged<Set<int>> onChanged,
  }) async {
    final selected = Set<int>.from(selectedIds);
    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        var query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = options
                .where((option) {
                  if (query.trim().isEmpty) return true;
                  return option.name.toLowerCase().contains(
                    query.toLowerCase(),
                  );
                })
                .toList(growable: false);

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: (value) => setSheetState(() => query = value),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final checked = selected.contains(item.id);
                        return CheckboxListTile(
                          value: checked,
                          title: Text(item.name),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (_) {
                            setSheetState(() {
                              if (!selected.add(item.id)) {
                                selected.remove(item.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(selected),
                    child: const Text('Aplicar'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null) return;
    onChanged(result);
  }

  Map<String, dynamic> _map(Object? raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _listOfMaps(Object? raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({
    required this.name,
    required this.subtitle,
    required this.avatarUrl,
    required this.avatarLocalPath,
  });

  final String name;
  final String subtitle;
  final String? avatarUrl;
  final String? avatarLocalPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLocal = avatarLocalPath != null && avatarLocalPath!.isNotEmpty;
    final hasRemote = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.yellow,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasLocal
                ? Image.file(File(avatarLocalPath!), fit: BoxFit.cover)
                : hasRemote
                ? Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.person_outline_rounded),
                  )
                : const Icon(Icons.person_outline_rounded, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuracoes',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.yellowLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.ink, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.slate,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class _VehicleImagePreview extends StatelessWidget {
  const _VehicleImagePreview({
    required this.imageUrl,
    required this.localPath,
    this.onTap,
  });

  final String? imageUrl;
  final String? localPath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasLocal = localPath != null && localPath!.isNotEmpty;
    final hasRemote = imageUrl != null && imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              color: Colors.white,
            ),
            clipBehavior: Clip.antiAlias,
            child: hasLocal
                ? Image.file(File(localPath!), fit: BoxFit.cover)
                : hasRemote
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const _VehicleImageEmpty(),
                  )
                : const _VehicleImageEmpty(),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 5),
                  Text(
                    'Trocar foto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileImagePreview extends StatelessWidget {
  const _ProfileImagePreview({
    required this.imageUrl,
    required this.localPath,
    this.onTap,
  });

  final String? imageUrl;
  final String? localPath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasLocal = localPath != null && localPath!.isNotEmpty;
    final hasRemote = imageUrl != null && imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.yellowLight,
                backgroundImage: hasLocal
                    ? FileImage(File(localPath!))
                    : hasRemote
                    ? NetworkImage(imageUrl!)
                    : null,
                child: (!hasLocal && !hasRemote)
                    ? const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.ink,
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Foto de perfil',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  onTap != null ? 'Toque para alterar' : '',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _VehicleImageEmpty extends StatelessWidget {
  const _VehicleImageEmpty();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: AppColors.surfaceSoft),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.no_photography_outlined,
              size: 28,
              color: AppColors.slate,
            ),
            SizedBox(height: 6),
            Text('Sem foto do veiculo'),
          ],
        ),
      ),
    );
  }
}

class _CoverageStatusBanner extends StatelessWidget {
  const _CoverageStatusBanner({
    required this.pendingRequest,
    required this.schoolsCount,
    required this.districtsCount,
  });

  final Map<String, dynamic>? pendingRequest;
  final int schoolsCount;
  final int districtsCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (pendingRequest != null) {
      final status = (pendingRequest!['status'] ?? '')
          .toString()
          .toLowerCase()
          .trim();
      final schoolsReq = pendingRequest!['requested_schools_count'] ?? 0;
      final districtsReq = pendingRequest!['requested_districts_count'] ?? 0;
      final reviewNote = (pendingRequest!['review_note'] ?? '')
          .toString()
          .trim();
      final photoLabels = <String>[
        if (pendingRequest!['has_avatar_change'] == true) 'foto do motorista',
        if (pendingRequest!['has_vehicle_image_change'] == true)
          'foto do veiculo',
      ];
      final coverageLabel = '$schoolsReq escola(s) e $districtsReq bairro(s)';
      final pendingLabel = photoLabels.isEmpty
          ? coverageLabel
          : '$coverageLabel, ${photoLabels.join(' e ')}';
      if (status == 'pending') {
        return _CoverageBannerContent(
          theme: theme,
          color: AppColors.yellowDark,
          icon: Icons.hourglass_top_rounded,
          title: 'Aguardando aprovacao',
          subtitle: '$pendingLabel aguardando revisao do administrador.',
          showPulse: true,
        );
      }
      if (status == 'rejected') {
        return _CoverageBannerContent(
          theme: theme,
          color: AppColors.danger,
          icon: Icons.cancel_outlined,
          title: 'Solicitacao reprovada',
          subtitle: reviewNote.isNotEmpty
              ? 'Motivo do admin: $reviewNote'
              : 'Sua ultima solicitacao foi reprovada pelo admin.',
        );
      }
      if (status == 'approved') {
        return _CoverageBannerContent(
          theme: theme,
          color: AppColors.success,
          icon: Icons.verified_rounded,
          title: 'Ultima solicitacao aprovada',
          subtitle: 'As alteracoes revisadas foram aprovadas pelo admin.',
        );
      }
    }

    if (schoolsCount > 0 || districtsCount > 0) {
      return _CoverageBannerContent(
        theme: theme,
        color: AppColors.success,
        icon: Icons.check_circle_rounded,
        title: 'Atendimento ativo',
        subtitle:
            '$schoolsCount escola(s) e $districtsCount bairro(s) visiveis nas buscas de responsaveis.',
      );
    }

    return _CoverageBannerContent(
      theme: theme,
      color: AppColors.muted,
      icon: Icons.info_outline_rounded,
      title: 'Nao configurado',
      subtitle:
          'Adicione escolas e bairros para aparecer nas buscas de responsaveis.',
    );
  }
}

class _CoverageRecentRequestsCard extends StatelessWidget {
  const _CoverageRecentRequestsCard({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5EA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DFC4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solicitacoes recentes',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) {
            final status = (item['status'] ?? '').toString().toLowerCase();
            final note = (item['review_note'] ?? '').toString().trim();
            final updatedAt = (item['updated_at'] ?? '').toString();
            final statusLabel = switch (status) {
              'pending' => 'Pendente',
              'approved' => 'Aprovada',
              'rejected' => 'Reprovada',
              _ => 'Registrada',
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                note.isNotEmpty
                    ? '• $statusLabel ($updatedAt) - $note'
                    : '• $statusLabel ($updatedAt)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.slate,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CoverageBannerContent extends StatelessWidget {
  const _CoverageBannerContent({
    required this.theme,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showPulse = false,
  });

  final ThemeData theme;
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showPulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                    if (showPulse) ...[
                      const SizedBox(width: 8),
                      _PulseDot(color: color),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.25,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _CoveragePickerRow extends StatelessWidget {
  const _CoveragePickerRow({
    required this.icon,
    required this.label,
    required this.count,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCount = count > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasCount ? AppColors.yellow : AppColors.border,
            ),
            color: hasCount
                ? AppColors.yellow.withValues(alpha: 0.06)
                : AppColors.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hasCount
                        ? AppColors.yellow.withValues(alpha: 0.22)
                        : AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: hasCount ? AppColors.yellowDark : AppColors.muted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (hasCount) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.yellow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Icon(
                  Icons.chevron_right_rounded,
                  color: enabled ? AppColors.slate : AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverageChips extends StatelessWidget {
  const _CoverageChips({required this.options, required this.selectedIds});

  final List<CatalogOption> options;
  final Set<int> selectedIds;

  @override
  Widget build(BuildContext context) {
    final selected = options.where((e) => selectedIds.contains(e.id)).toList();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: selected
          .map(
            (option) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.yellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.yellow.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: AppColors.yellowDark,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    option.name,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _DistrictShiftEditor extends StatelessWidget {
  const _DistrictShiftEditor({
    required this.districtOptions,
    required this.shiftOptions,
    required this.districtShiftMap,
    required this.enabled,
    required this.onToggleShift,
  });

  final List<CatalogOption> districtOptions;
  final List<CatalogOption> shiftOptions;
  final Map<int, Set<int>> districtShiftMap;
  final bool enabled;
  final void Function(int districtId, int shiftId) onToggleShift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (districtShiftMap.isEmpty) return const SizedBox.shrink();

    final districtById = {for (final d in districtOptions) d.id: d};
    final sortedEntries = districtShiftMap.entries.toList()
      ..sort((a, b) {
        final aName = districtById[a.key]?.name ?? a.key.toString();
        final bName = districtById[b.key]?.name ?? b.key.toString();
        return aName.compareTo(bName);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Periodos por bairro',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.slate,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        ...sortedEntries.map((entry) {
          final district = districtById[entry.key];
          final selectedShiftIds = entry.value;
          final allSelected =
              shiftOptions.isNotEmpty &&
              shiftOptions.every((s) => selectedShiftIds.contains(s.id));

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selectedShiftIds.isNotEmpty
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
              color: AppColors.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: selectedShiftIds.isNotEmpty
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 15,
                          color: selectedShiftIds.isNotEmpty
                              ? AppColors.success
                              : AppColors.muted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          district?.name ?? 'Bairro #${entry.key}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (selectedShiftIds.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: allSelected
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.yellowLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            allSelected
                                ? 'Todos os turnos'
                                : '${selectedShiftIds.length}/${shiftOptions.length} turnos',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: allSelected
                                  ? AppColors.success
                                  : AppColors.yellowDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: shiftOptions
                        .map((shift) {
                          final isSelected = selectedShiftIds.contains(
                            shift.id,
                          );
                          return GestureDetector(
                            onTap: enabled
                                ? () => onToggleShift(entry.key, shift.id)
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.yellow
                                    : AppColors.surfaceSoft,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.yellowDark
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 13,
                                      color: AppColors.ink,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    shift.name,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: isSelected
                                              ? AppColors.ink
                                              : AppColors.slate,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 32,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nao foi possivel carregar',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.slate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
