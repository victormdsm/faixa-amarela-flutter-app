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
import '../../../../core/presentation/widgets/change_password_dialog.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../../core/presentation/widgets/faixa_image_picker.dart';
import '../../../../core/presentation/widgets/faixa_profile_hero.dart';
import '../../../../core/presentation/widgets/faixa_section_card.dart';
import '../../../../data/nestjs_user_repository.dart';
import '../../../../domain/models/driver_profile.dart';
import '../../../../domain/models/driver_profile_change_request.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../../catalog/data/catalog_repository.dart';
import '../providers/driver_portal_providers.dart';
import '../widgets/driver_coverage_section.dart';
import '../widgets/driver_vehicle_section.dart';
import 'driver_settings_change_detection.dart';

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
  final _infoController = TextEditingController();
  final _cnhController = TextEditingController();
  final _vehicleBrandController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _picker = ImagePicker();

  bool _hydrated = false;
  bool _isSaving = false;
  bool _isSyncing = false;
  bool _vehicleEditMode = false;
  int? _vehicleId;
  String? _avatarImageUrl;
  String? _avatarImageLocalPath;
  String? _vehicleImageUrl;
  String? _vehicleImageLocalPath;
  String? _email;
  String? _cpf;
  final Set<int> _selectedSchoolIds = <int>{};
  final Map<int, Set<int>> _districtShiftMap = <int, Set<int>>{};
  Set<int> _originalSelectedSchoolIds = <int>{};
  Map<int, Set<int>> _originalDistrictShiftMap = <int, Set<int>>{};
  late final ProviderSubscription<AsyncValue<Map<String, dynamic>>>
  _profileSubscription;
  // Valores carregados do servidor: base para detectar edições do motorista
  // e não enviar campos intocados (CNH) ou incompletos (veículo sem placa).
  String _originalCnh = '';
  String _originalVehicleBrand = '';
  String _originalVehicleColor = '';
  String _originalVehicleYear = '';
  String _originalVehiclePlate = '';

  @override
  void initState() {
    super.initState();
    // Binding do form fora do build: com fireImmediately, dados JÁ presentes
    // (cache do Hive ou provider keepAlive de visita anterior) preenchem os
    // controllers na abertura — corrige o bug do formulário abrir vazio
    // quando os dados existiam mas nenhuma transição de estado ocorria após
    // o primeiro build. Dados que chegarem depois seguem a mesma regra:
    // primeira carga hidrata o form; cargas seguintes sincronizam sem
    // sobrescrever edições em andamento.
    _profileSubscription = ref.listenManual(
      driverProfileProvider,
      fireImmediately: true,
      (previous, next) {
        next.whenData((data) {
          if (!_hydrated) {
            _applyProfile(data);
          } else {
            _syncRemoteState(data);
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _profileSubscription.close();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
    // APP-10: a seção de solicitações é alimentada pelo provider canônico
    // (/drivers/me/profile-change-requests) — o /drivers/me não expõe mais
    // as chaves coverageChangeRequest(sRecent).
    final changeRequestsAsync = ref.watch(driverProfileChangeRequestsProvider);
    final schoolsAsync = ref.watch(schoolsCatalogProvider);
    final districtsAsync = ref.watch(districtsCatalogProvider);
    final shiftsAsync = ref.watch(shiftsCatalogProvider);
    final shiftOptions = (shiftsAsync.value ?? const <CatalogOption>[])
        .where((e) => e.id > 0)
        .toList(growable: false);
    final effectiveShiftOptions = shiftOptions.isEmpty
        ? _fallbackShiftOptions
        : shiftOptions;

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
            tooltip: 'Sincronizar',
            onPressed: (_isSaving || _isSyncing) ? null : _syncProfile,
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      bottomNavigationBar: profileAsync.maybeWhen(
        data: (_) => SafeArea(
          top: false,
          // Alguns aparelhos (MIUI/gesture bar custom) reportam inset bottom
          // como 0 e o botão fica sob a barra de navegação do Android.
          // O piso mínimo garante respiro mesmo nesses casos.
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
          onRetry: _syncProfile,
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
                      // APP-06: troca de e-mail exige verificação fora do app —
                      // o campo é somente leitura para não dar a ilusão de
                      // que o "Salvar" persiste um novo e-mail.
                      readOnly: true,
                      enabled: !_isSaving,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                        helperText: 'Para alterar o e-mail, fale com o suporte.',
                      ),
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
              FaixaSectionCard(
                icon: Icons.lock_outline_rounded,
                title: 'Segurança',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.ink,
                  ),
                  title: const Text('Alterar senha'),
                  subtitle: const Text('Senha atual + nova senha'),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                  ),
                  onTap: _isSaving ? null : () => _changePassword(context),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              DriverCoverageSection(
                schoolsAsync: schoolsAsync,
                districtsAsync: districtsAsync,
                shiftOptions: effectiveShiftOptions,
                selectedSchoolIds: _selectedSchoolIds,
                districtShiftMap: _districtShiftMap,
                requestsAsync: changeRequestsAsync,
                pendingRequest: _latestChangeRequest(
                  changeRequestsAsync.value,
                ),
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
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () => context.push(AppRoutes.driverChangeRequests),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Ver histórico'),
                  ),
                ),
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
    _infoController.text = (data['information'] ?? '').toString();
    _cnhController.text = (data['cnh'] ?? '').toString();
    _originalCnh = _cnhController.text.trim();
    _avatarImageUrl = data['avatarUrl']?.toString();
    _avatarImageLocalPath = null;

    final van = _map(data['van']);
    // van inexistente é serializada com id 0 (DriverProfile.toJson): coage
    // para null para nunca enviar vehicleId 0 ao backend (@Min(1) → 400).
    _vehicleId = DriverProfile.normalizeVanId(van['id'] as num?);
    _vehicleBrandController.text = (van['model'] ?? '').toString();
    _vehicleColorController.text = (van['color'] ?? '').toString();
    _vehicleYearController.text = (van['year'] ?? '').toString();
    _vehiclePlateController.text = (van['plate'] ?? '').toString();
    _vehicleImageUrl = van['imageUrl']?.toString();
    _vehicleImageLocalPath = null;
    _originalVehicleBrand = _vehicleBrandController.text.trim();
    _originalVehicleColor = _vehicleColorController.text.trim();
    _originalVehicleYear = _vehicleYearController.text.trim();
    _originalVehiclePlate = _vehiclePlateController.text.trim();

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

  /// Sincroniza com dados frescos do servidor sem tocar nos campos de texto
  /// (o motorista pode estar editando). Atualiza avatar e foto do veículo —
  /// é o que faz a foto aprovada aparecer sozinha quando o push
  /// `driver_profile_change_reviewed` invalida o provider. As solicitações
  /// de alteração vêm do [driverProfileChangeRequestsProvider] (APP-10).
  void _syncRemoteState(Map<String, dynamic> data) {
    if (_avatarImageLocalPath == null) {
      _avatarImageUrl = data['avatarUrl']?.toString();
    }

    final van = _map(data['van']);
    _vehicleId = DriverProfile.normalizeVanId(van['id'] as num?);
    if (_vehicleImageLocalPath == null) {
      _vehicleImageUrl = van['imageUrl']?.toString();
    }

    if (mounted) setState(() {});
  }

  /// Escolhe a solicitação exibida no banner: a pendente mais recente, se
  /// houver; senão a última do histórico (aprovada/reprovada).
  DriverProfileChangeRequest? _latestChangeRequest(
    List<DriverProfileChangeRequest>? items,
  ) {
    if (items == null || items.isEmpty) return null;
    final sorted = items.toList(growable: false)..sort((a, b) {
      final aDate = a.createdAt ?? DateTime(1970);
      final bDate = b.createdAt ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });
    for (final item in sorted) {
      if (item.status.toLowerCase().trim() == 'pending') return item;
    }
    return sorted.first;
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

  /// Sincronização manual e explícita (única fonte de fetch além da primeira
  /// carga sem cache e do push de aprovação). Enquanto sincroniza, mostra um
  /// indicador sutil no AppBar e mantém os dados atuais na tela; se falhar
  /// com cache presente, avisa em snackbar e NÃO zera o formulário.
  Future<void> _syncProfile() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    final hadData = ref.read(driverProfileProvider).hasValue;
    final wasHydrated = _hydrated;
    // Pedido explícito do usuário: quando os dados frescos chegarem, o form
    // é re-vinculado por completo (ver _profileSubscription no initState).
    _hydrated = false;
    try {
      await ref.read(driverProfileProvider.notifier).refresh();
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: 'Perfil sincronizado com o servidor.',
        type: AppFeedbackType.success,
      );
    } catch (_) {
      // Falhou: o controller manteve os dados anteriores no estado; volta ao
      // modo não-destrutivo para não clobberar edições no próximo sync/push.
      _hydrated = wasHydrated;
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: hadData
            ? 'Não foi possível sincronizar agora. Mantendo os dados salvos neste aparelho.'
            : 'Não foi possível carregar o perfil. Tente novamente.',
        type: AppFeedbackType.warning,
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  /// APP-05: troca de senha de verdade — valida os campos no diálogo e
  /// chama `PUT /users/me/password` (senha atual + nova senha). O backend
  /// responde 401 com "Senha atual incorreta." quando a atual não confere;
  /// a mensagem vai direto para o snackbar.
  Future<void> _changePassword(BuildContext context) async {
    final result = await showDialog<PasswordResult>(
      context: context,
      builder: (_) => const ChangePasswordDialog(),
    );
    if (result == null || !context.mounted) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(userRepositoryProvider)
          .changePassword(
            currentPassword: result.currentPassword,
            newPassword: result.newPassword,
          );
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        message: 'Senha alterada com sucesso.',
        type: AppFeedbackType.success,
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(context, message: e.message, type: AppFeedbackType.error);
    } catch (_) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        message: 'Falha ao alterar a senha.',
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

  /// Edição nos dados da van (placa/marca/cor/ano) comparada aos valores
  /// carregados do servidor. Desde que os dados da van passaram a exigir
  /// aprovação do admin, essa detecção alimenta tanto a validação da placa
  /// quanto o envio dos campos na solicitação.
  bool _hasVehicleDataChanges() {
    return hasVehicleDataChanges(
      brand: _vehicleBrandController.text.trim(),
      color: _vehicleColorController.text.trim(),
      year: _vehicleYearController.text.trim(),
      plate: _vehiclePlateController.text.trim(),
      originalBrand: _originalVehicleBrand,
      originalColor: _originalVehicleColor,
      originalYear: _originalVehicleYear,
      originalPlate: _originalVehiclePlate,
    );
  }

  bool _hasCoverageChanges() {
    return hasCoverageChanges(
      selectedSchoolIds: _selectedSchoolIds,
      originalSelectedSchoolIds: _originalSelectedSchoolIds,
      districtShiftMap: _districtShiftMap,
      originalDistrictShiftMap: _originalDistrictShiftMap,
      hasNewAvatarImage: _avatarImageLocalPath != null,
      hasNewVehicleImage: _vehicleImageLocalPath != null,
      hasVehicleDataChanges: _hasVehicleDataChanges(),
    );
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

    // Detecta edições nos dados do veículo comparando com os valores
    // carregados do servidor. Dados da van (e foto da van) não são mais
    // persistidos direto: seguem na solicitação de aprovação do admin.
    // A placa continua obrigatória para enviar qualquer alteração da van.
    final vehicleBrand = _vehicleBrandController.text.trim();
    final vehicleColor = _vehicleColorController.text.trim();
    final vehicleYear = _vehicleYearController.text.trim();
    final vehiclePlate = _vehiclePlateController.text.trim();
    final hasVehicleChanges = _hasVehicleDataChanges();
    if (hasVehicleChanges && vehiclePlate.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Informe a placa do veículo.')),
      );
      return;
    }

    // CNH só é enviada quando o motorista editou o campo — reenviar o valor
    // intocado (ou vazio) poderia sobrescrever o dado no servidor.
    final cnh = _cnhController.text.trim();
    final cnhChanged = cnh != _originalCnh;

    final hasCoverageChanges = _hasCoverageChanges();
    // APP-02: o mapa bairro→turnos só é enviado quando o motorista editou
    // de fato — antes, uma troca de foto/avatar reenviava o mapa inteiro.
    final districtShiftEdited = hasDistrictShiftChanges(
      districtShiftMap: _districtShiftMap,
      originalDistrictShiftMap: _originalDistrictShiftMap,
    );

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
          districtShiftMap: districtShiftEdited
              ? {
                  for (final entry in _districtShiftMap.entries)
                    entry.key: (entry.value.toList()..sort()),
                }
              : null,
          avatarImagePath: avatarUrl,
          vehicleImagePath: vehicleImageUrl,
          vehicleId: _vehicleId,
          requestNote: null,
          // Dados da van trafegam na solicitação de aprovação (contrato
          // congelado do backend): enviados apenas quando editados.
          requestedVehiclePlaca: hasVehicleChanges ? vehiclePlate : null,
          requestedVehicleMarca: hasVehicleChanges ? vehicleBrand : null,
          requestedVehicleCor: hasVehicleChanges ? vehicleColor : null,
          requestedVehicleAno: hasVehicleChanges ? vehicleYear : null,
        );
        coverageRequestSubmitted = true;
      }

      updatedProfile = await ref
          .read(driverProfileRepositoryProvider)
          .updateBasicProfile(
            name: _nameController.text.trim(),
            cellPhone: _phoneController.text.trim(),
            information: _infoController.text.trim(),
            cnh: cnhChanged ? cnh : null,
          );

      _applyProfile(updatedProfile.toJson());
      try {
        await ref.read(driverProfileProvider.notifier).refresh();
      } catch (_) {
        // O save já foi persistido e aplicado ao form acima; a resync do
        // provider é best-effort — falha de rede aqui não desfaz o save.
      }

      if (context.mounted) {
        if (coverageRequestSubmitted) {
          showAppSnackBar(
            context,
            message: 'Alterações enviadas para aprovação do administrador.',
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
