import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/app_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/catalog_option.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../../core/presentation/widgets/faixa_image_picker.dart';
import '../../../../core/presentation/widgets/faixa_profile_hero.dart';
import '../../../../core/presentation/widgets/faixa_section_card.dart';
import '../../../../domain/models/driver_profile.dart';
import '../../../../domain/models/driver_profile_change_request.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../../catalog/data/catalog_repository.dart';
import '../providers/driver_portal_providers.dart';
import '../widgets/driver_coverage_section.dart';
import '../widgets/driver_password_section.dart';
import '../widgets/driver_vehicle_section.dart';

class DriverSettingsPage extends ConsumerStatefulWidget {
  const DriverSettingsPage({super.key});

  @override
  ConsumerState<DriverSettingsPage> createState() => _DriverSettingsPageState();
}

class _DriverSettingsPageState extends ConsumerState<DriverSettingsPage> {
  static const _maxUploadBytes = 900 * 1024;
  static const List<CatalogOption> _fallbackShiftOptions = [
    CatalogOption(id: 1, name: 'Manhã'),
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
  List<DriverProfileChangeRequest> _coverageChangeRequestsRecent = const [];
  final Set<int> _selectedSchoolIds = <int>{};
  final Map<int, Set<int>> _districtShiftMap = <int, Set<int>>{};
  Set<int> _originalSelectedSchoolIds = <int>{};
  Map<int, Set<int>> _originalDistrictShiftMap = <int, Set<int>>{};

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

    // Status bar coerente com o tema (ícones ink sobre fundo claro), mesmo
    // quando esta página é empilhada sobre telas com outro overlay style.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      appBar: FaixaAppBar.screen(
        title: 'Perfil e conta',
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _isSaving ? null : _refreshProfile,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      bottomNavigationBar: profileAsync.maybeWhen(
        data: (_) => SafeArea(
          top: false,
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
            child: FilledButton.icon(
              onPressed: _isSaving ? null : () => _save(context),
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Salvando...' : 'Salvar configurações'),
            ),
          ),
        ),
        orElse: () => null,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => FaixaErrorState(
          message: error.toString(),
          onRetry: _refreshProfile,
        ),
        data: (_) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              160,
            ),
            children: [
              FaixaProfileHero(
                name: _nameController.text.trim().isEmpty
                    ? 'Tio da van'
                    : _nameController.text.trim(),
                subtitle: _vehiclePlateController.text.trim().isEmpty
                    ? 'Perfil, atendimento e veículo'
                    : 'Veículo ${_vehiclePlateController.text.trim().toUpperCase()}',
                avatarUrl: _avatarImageUrl,
                avatarLocalPath: _avatarImageLocalPath,
                onAvatarTap: _isSaving ? null : _pickAvatarImage,
                avatarShape: BoxShape.circle,
              ),
              const SizedBox(height: AppSpacing.lg),
              FaixaSectionCard(
                icon: Icons.account_circle_rounded,
                title: 'Perfil do tio da van',
                subtitle: 'Dados de contato, foto e informações públicas.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FaixaImagePicker.avatar(
                      imageUrl: _avatarImageUrl,
                      localPath: _avatarImageLocalPath,
                      onTap: _isSaving ? null : _pickAvatarImage,
                      label: 'Foto de perfil',
                    ),
                    if (_avatarImageLocalPath != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () =>
                                  setState(() => _avatarImageLocalPath = null),
                        icon: const Icon(Icons.undo_rounded),
                        label: const Text('Desfazer foto de perfil'),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
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
                    const SizedBox(height: AppSpacing.md),
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
                          return 'Informe um e-mail válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      key: ValueKey('cpf-${_cpf ?? ''}'),
                      initialValue: _cpf ?? '',
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'CPF',
                        prefixIcon: Icon(Icons.badge_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _phoneController,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Telefone / WhatsApp',
                        prefixIcon: Icon(Icons.phone_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _cnhController,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(
                        labelText: 'CNH',
                        prefixIcon: Icon(Icons.credit_card_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _infoController,
                      enabled: !_isSaving,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Sobre / Informações',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.info_outline_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FaixaSectionCard(
                icon: Icons.directions_bus_filled_rounded,
                title: 'Veículo',
                subtitle: 'Foto, modelo, cor, ano e placa usados no app.',
                child: DriverVehicleSection(
                  brandController: _vehicleBrandController,
                  colorController: _vehicleColorController,
                  yearController: _vehicleYearController,
                  plateController: _vehiclePlateController,
                  isSaving: _isSaving,
                  editMode: _vehicleEditMode,
                  imageUrl: _vehicleImageUrl,
                  localPath: _vehicleImageLocalPath,
                  onPickImage: _pickVehicleImage,
                  onToggleEdit: () =>
                      setState(() => _vehicleEditMode = !_vehicleEditMode),
                  onUndoImage: () =>
                      setState(() => _vehicleImageLocalPath = null),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (isAdminAppUser)
                FaixaSectionCard(
                  icon: Icons.lock_outline_rounded,
                  title: 'Alterar senha',
                  child: DriverPasswordSection(
                    isSaving: _isSaving,
                    passwordController: _passwordController,
                    passwordConfirmController: _passwordConfirmController,
                    showCurrentPassword: false,
                  ),
                ),
              if (isAdminAppUser) const SizedBox(height: AppSpacing.lg),
              DriverCoverageSection(
                schoolsAsync: schoolsAsync,
                districtsAsync: districtsAsync,
                shiftOptions: effectiveShiftOptions,
                selectedSchoolIds: _selectedSchoolIds,
                districtShiftMap: _districtShiftMap,
                requestsAsync: AsyncValue.data(_coverageChangeRequestsRecent),
                pendingRequest: _coverageChangeRequest,
                isSaving: _isSaving,
                onSchoolsChanged: (value) => setState(() {
                  _selectedSchoolIds
                    ..clear()
                    ..addAll(value);
                }),
                onDistrictsChanged: (value) => setState(() {
                  final keep = value.toSet();
                  _districtShiftMap.removeWhere(
                    (key, _) => !keep.contains(key),
                  );
                  for (final id in keep) {
                    _districtShiftMap.putIfAbsent(id, () => <int>{});
                  }
                }),
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
              const SizedBox(height: AppSpacing.lg),
              FaixaSectionCard(
                icon: Icons.history_rounded,
                title: 'Minhas solicitações de alteração',
                subtitle: 'Acompanhe o status de escolas, bairros, turnos e fotos enviadas.',
                trailing: FilledButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () => context.push(AppRoutes.driverChangeRequests),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Ver histórico'),
                ),
                child: const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _confirmSignOut,
                icon: const Icon(Icons.logout_rounded),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                label: const Text('Sair'),
              ),
            ],
          ),
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
    _phoneController.text = (data['cellPhone'] ?? '').toString();
    _passwordController.clear();
    _passwordConfirmController.clear();
    _infoController.text = (data['information'] ?? '').toString();
    _cnhController.text = (data['cnh'] ?? '').toString();
    _avatarImageUrl = data['avatarUrl']?.toString();
    _avatarImageLocalPath = null;
    _coverageChangeRequest = _map(data['coverageChangeRequest']);
    if (_coverageChangeRequest != null && _coverageChangeRequest!.isEmpty) {
      _coverageChangeRequest = null;
    }
    _coverageChangeRequestsRecent = _listOfMaps(
      data['coverageChangeRequestsRecent'],
    ).map(_toChangeRequest).toList(growable: false);

    final van = _map(data['van']);
    _vehicleBrandController.text = (van['model'] ?? '').toString();
    _vehicleColorController.text = (van['color'] ?? '').toString();
    _vehicleYearController.text = (van['year'] ?? '').toString();
    _vehiclePlateController.text = (van['plate'] ?? '').toString();
    _vehicleImageUrl = van['imageUrl']?.toString();
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
      final shifts = ((district['shiftIds'] as List?) ?? const [])
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

    if (mounted) setState(() {});
  }

  DriverProfileChangeRequest _toChangeRequest(Map<String, dynamic> raw) {
    return DriverProfileChangeRequest(
      id: (raw['id'] as num?)?.toInt() ?? 0,
      driverUserId: (raw['driverUserId'] as num?)?.toInt() ?? 0,
      requestedByUserId: (raw['requestedByUserId'] as num?)?.toInt() ?? 0,
      status: (raw['status'] ?? '').toString(),
      reviewNote: raw['reviewNote']?.toString(),
      reviewedAt: raw['reviewedAt'] != null
          ? DateTime.tryParse(raw['reviewedAt'].toString())
          : null,
      createdAt: raw['createdAt'] != null
          ? DateTime.tryParse(raw['createdAt'].toString())
          : null,
    );
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
      showAppSnackBar(
        context,
        message:
            'A foto selecionada ainda ficou grande para envio. Escolha outra foto menor.',
        type: AppFeedbackType.warning,
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

  void _refreshProfile() {
    setState(() => _hydrated = false);
    ref.read(driverProfileProvider.notifier).refresh();
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do app?'),
        content: const Text('Sua sessão será encerrada neste aparelho.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sair'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await ref.read(appSessionControllerProvider.notifier).signOut();
    }
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
        const SnackBar(content: Text('Sessão expirada. Entre novamente.')),
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
          const SnackBar(content: Text('A confirmação de senha não confere.')),
        );
        return;
      }
    }

    final hasCoverageChanges = _hasCoverageChanges();

    setState(() => _isSaving = true);
    DriverProfile? updatedProfile;
    try {
      bool coverageRequestSubmitted = false;

      if (hasCoverageChanges) {
        final repo = ref.read(driverProfileChangeRequestRepositoryProvider);
        String? avatarUrl;
        String? vehicleImageUrl;
        if (_avatarImageLocalPath != null) {
          avatarUrl = await repo.uploadImage(
            _avatarImageLocalPath!,
            type: 'avatar',
          );
        }
        if (_vehicleImageLocalPath != null) {
          vehicleImageUrl = await repo.uploadImage(
            _vehicleImageLocalPath!,
            type: 'vehicle',
          );
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
      await ref.read(driverProfileProvider.notifier).refresh();

      if (context.mounted) {
        if (coverageRequestSubmitted) {
          showAppSnackBar(
            context,
            message:
                'Perfil atualizado. As alterações que precisam de aprovação foram enviadas ao admin.',
            type: AppFeedbackType.warning,
          );
        } else {
          showAppSnackBar(
            context,
            message: 'Configurações atualizadas com sucesso.',
            type: AppFeedbackType.success,
          );
        }
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(context, message: e.message, type: AppFeedbackType.error);
    } catch (e, st) {
      debugPrint('[DriverSettingsPage._save] erro: $e');
      debugPrint(st.toString());
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        message: 'Falha ao salvar configurações. Tente novamente.',
        type: AppFeedbackType.error,
      );
    } finally {
      if (context.mounted) setState(() => _isSaving = false);
    }
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
