import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/app_error_reporter.dart';
import '../../../../core/models/catalog_option.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../../core/presentation/widgets/faixa_delete_child_dialog.dart';
import '../../../../core/presentation/widgets/faixa_section_card.dart';
import '../../../../domain/models/address_suggestion.dart';
import '../../../../domain/models/child.dart';
import '../../../../domain/models/enrollment.dart';
import '../../../../features/catalog/data/catalog_repository.dart';
import '../../../../ui/core/widgets/status_pill.dart';
import '../providers/parent_portal_providers.dart';
import '../widgets/address_map_picker.dart';
import '../widgets/city_state_fields.dart';

final _childDetailAddressesProvider = FutureProvider.family
    .autoDispose<List<Map<String, dynamic>>, int>((ref, childId) async {
      final repo = ref.watch(childrenRepositoryProvider);
      return repo.getChildAddresses(childId);
    });

final _childDetailEnrollmentProvider = FutureProvider.family
    .autoDispose<Enrollment?, int>((ref, childId) async {
      final repo = ref.watch(enrollmentsRepositoryProvider);
      final active = await repo.getActiveEnrollments();
      return active.where((e) => e.childId == childId).firstOrNull;
    });

class ChildDetailPage extends ConsumerWidget {
  const ChildDetailPage({super.key, required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolsAsync = ref.watch(schoolsCatalogProvider);
    final shiftsAsync = ref.watch(shiftsCatalogProvider);
    final addressesAsync = ref.watch(_childDetailAddressesProvider(child.id));
    final enrollmentAsync = ref.watch(_childDetailEnrollmentProvider(child.id));

    final schoolName = schoolsAsync.when(
      loading: () => 'Carregando...',
      error: (error, _) => 'Não informado',
      data: (schools) {
        final school = schools.where((s) => s.id == child.schoolId).firstOrNull;
        return school?.name ?? 'Não informado';
      },
    );

    final shiftName = shiftsAsync.when(
      loading: () => 'Carregando...',
      error: (error, _) => 'Não informado',
      data: (shifts) {
        final shift = shifts.where((s) => s.id == child.shiftId).firstOrNull;
        return shift?.name ?? 'Não informado';
      },
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.surfaceSoft,
        appBar: FaixaAppBar.screen(
          title: 'Detalhes do dependente',
          actions: [
            IconButton(
              tooltip: 'Editar',
              onPressed: () => _editChild(context),
              icon: const Icon(Icons.edit_rounded, size: 20),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          // Mesmo padrão do driver_settings: piso mínimo para aparelhos
          // (MIUI/gesture bar custom) que reportam inset bottom 0.
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
            child: _ActionButtons(
              onEdit: () => _editChild(context),
              onDelete: () => _confirmDelete(context, ref),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _HeaderCard(
              child: child,
              schoolName: schoolName,
              shiftName: shiftName,
            ),
            if (child.uuid != null && child.uuid!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _ChildCodeSection(uuid: child.uuid!),
            ],
            const SizedBox(height: AppSpacing.lg),
            _AddressSection(childId: child.id, addressesAsync: addressesAsync),
            const SizedBox(height: AppSpacing.lg),
            _EnrollmentSection(
              enrollmentAsync: enrollmentAsync,
              onCancelEnrollment: (enrollment) =>
                  _confirmCancelEnrollment(context, ref, enrollment),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  void _editChild(BuildContext context) {
    context.push(AppRoutes.parentChildrenAdd, extra: child);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    try {
      final confirmed = await showDeleteChildConfirmation(
        context,
        child: child,
        loadActiveEnrollment: () => ref
            .read(childrenControllerProvider.notifier)
            .findActiveEnrollmentForChild(child.id),
      );

      if (!confirmed || !context.mounted) return;

      await ref.read(childrenControllerProvider.notifier).delete(child.id);

      if (context.mounted) {
        showAppSnackBar(
          context,
          message: '${child.name} removido(a).',
          type: AppFeedbackType.warning,
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: AppErrorReporter.messageFor(e),
          type: AppFeedbackType.error,
        );
      }
    }
  }

  Future<void> _confirmCancelEnrollment(
    BuildContext context,
    WidgetRef ref,
    Enrollment enrollment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        title: const Text('Cancelar matrícula'),
        content: Text(
          'Deseja cancelar a matrícula de ${child.name} com o motorista '
          '${enrollment.driverName}? O vínculo de transporte será encerrado.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.surface,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancelar matrícula'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(enrollmentsControllerProvider.notifier)
          .cancel(enrollment.id);
      ref.invalidate(_childDetailEnrollmentProvider(child.id));

      if (context.mounted) {
        showAppSnackBar(
          context,
          message: 'Matrícula cancelada.',
          type: AppFeedbackType.warning,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: AppErrorReporter.messageFor(e),
          type: AppFeedbackType.error,
        );
      }
    }
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.child,
    required this.schoolName,
    required this.shiftName,
  });

  final Child child;
  final String schoolName;
  final String shiftName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FaixaSectionCard(
      child: Column(
        children: [
          AppNetworkAvatar(
            name: child.name,
            imageUrl: child.photoUrl,
            radius: 48,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            child.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.school_rounded,
            label: 'Escola',
            value: schoolName,
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.schedule_rounded,
            label: 'Turno',
            value: shiftName,
          ),
          if (child.isInDebt) ...[
            const SizedBox(height: AppSpacing.md),
            const StatusPill(label: 'Inadimplente', color: AppColors.danger),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.slate,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChildCodeSection extends StatelessWidget {
  const _ChildCodeSection({required this.uuid});

  final String uuid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FaixaSectionCard(
      icon: Icons.key_rounded,
      title: 'Código da criança',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  uuid,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copiar código',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: uuid));
                  if (context.mounted) {
                    showAppSnackBar(
                      context,
                      message: 'Código copiado',
                      type: AppFeedbackType.success,
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Compartilhe este código com o motorista em vez do CPF.',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.slate),
          ),
        ],
      ),
    );
  }
}

class _AddressSection extends ConsumerWidget {
  const _AddressSection({required this.childId, required this.addressesAsync});

  final int childId;
  final AsyncValue<List<Map<String, dynamic>>> addressesAsync;

  static bool _isDefault(Map<String, dynamic> addr) {
    final raw = addr['isDefault'] ?? addr['is_default'];
    return raw == true || raw == 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FaixaSectionCard(
      icon: Icons.location_on_rounded,
      title: 'Endereços',
      child: addressesAsync.when(
        loading: () => const SizedBox(
          height: 40,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => AppInfoBanner(
          message: AppErrorReporter.messageFor(error),
          icon: Icons.error_outline_rounded,
          color: AppColors.danger,
        ),
        data: (addresses) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (addresses.isEmpty)
                Text(
                  'Nenhum endereço cadastrado ainda.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.slate),
                )
              else
                ...addresses.map(
                  (addr) => _AddressTile(
                    address: addr,
                    isDefault: _isDefault(addr),
                    onSetDefault: _isDefault(addr)
                        ? null
                        : () => _setDefault(context, ref, addr),
                    onDelete: () => _confirmDelete(context, ref, addr),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () =>
                    _openAddressForm(context, ref, addresses.isEmpty),
                icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                label: const Text('Adicionar endereço'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _setDefault(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> addr,
  ) async {
    final addressId = (addr['id'] as num?)?.toInt();
    if (addressId == null) return;
    try {
      await ref
          .read(childrenRepositoryProvider)
          .setChildAddressDefault(childId: childId, addressId: addressId);
      ref.invalidate(_childDetailAddressesProvider(childId));
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: 'Endereço padrão atualizado.',
          type: AppFeedbackType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: AppErrorReporter.messageFor(e),
          type: AppFeedbackType.error,
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> addr,
  ) async {
    final addressId = (addr['id'] as num?)?.toInt();
    if (addressId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        title: const Text('Excluir endereço'),
        content: const Text(
          'Deseja excluir este endereço? Se ele for o padrão, outro endereço '
          'será definido como padrão automaticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.surface,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(childrenRepositoryProvider)
          .deleteChildAddress(childId: childId, addressId: addressId);
      ref.invalidate(_childDetailAddressesProvider(childId));
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: 'Endereço removido.',
          type: AppFeedbackType.warning,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: AppErrorReporter.messageFor(e),
          type: AppFeedbackType.error,
        );
      }
    }
  }

  Future<void> _openAddressForm(
    BuildContext context,
    WidgetRef ref,
    bool isFirstAddress,
  ) async {
    final address = await showModalBottomSheet<ChildAddress>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _AddressFormSheet(),
    );
    if (address == null || !context.mounted) return;

    try {
      await ref
          .read(childrenRepositoryProvider)
          .createChildAddress(
            childId: childId,
            address: address,
            isDefault: isFirstAddress,
          );
      ref.invalidate(_childDetailAddressesProvider(childId));
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: 'Endereço adicionado.',
          type: AppFeedbackType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: AppErrorReporter.messageFor(e),
          type: AppFeedbackType.error,
        );
      }
    }
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.isDefault,
    this.onSetDefault,
    this.onDelete,
  });

  final Map<String, dynamic> address;
  final bool isDefault;
  final VoidCallback? onSetDefault;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final street = (address['street'] ?? '').toString();
    final number = (address['number'] ?? '').toString();
    final complement = (address['reference'] ?? address['complement'] ?? '')
        .toString();
    final district = (address['neighborhood'] ?? address['district'] ?? '')
        .toString();
    final city = (address['city'] ?? '').toString();
    final state = (address['state'] ?? '').toString();
    final zipcode = (address['zipcode'] ?? address['zipCode'] ?? '').toString();

    final parts = <String>[
      if (street.isNotEmpty) street,
      if (number.isNotEmpty) number,
      if (complement.isNotEmpty) complement,
      if (district.isNotEmpty) district,
      if (city.isNotEmpty) state.isNotEmpty ? '$city/$state' : city,
      if (zipcode.isNotEmpty) 'CEP: $zipcode',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.home_rounded, size: 18, color: AppColors.muted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parts.join(', '),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.ink),
                ),
                if (isDefault) ...[
                  const SizedBox(height: AppSpacing.xs),
                  const StatusPill(label: 'Padrão', color: AppColors.success),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opções do endereço',
            iconSize: 20,
            onSelected: (value) {
              if (value == 'default') {
                onSetDefault?.call();
              } else if (value == 'delete') {
                onDelete?.call();
              }
            },
            itemBuilder: (context) => [
              if (!isDefault && onSetDefault != null)
                const PopupMenuItem(
                  value: 'default',
                  child: Text('Tornar padrão'),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Excluir',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressFormSheet extends ConsumerStatefulWidget {
  const _AddressFormSheet();

  @override
  ConsumerState<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _streetCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _complementCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _zipCodeCtrl = TextEditingController();

  // Mesmo fluxo do add_child_page: cidade/UF (obrigatórios) habilitam o mapa
  // estilo Uber (pin central + busca + GPS). [_marker] null = ponto nunca
  // definido; salvar assim exige consentimento (backend re-geocodifica).
  CatalogOption? _city;
  String? _stateUf;
  LatLng? _marker;
  String? _resolvedLabel;

  String? get _cityBias {
    final city = _city;
    final uf = _stateUf;
    if (city == null || uf == null) return null;
    return '${city.name}, $uf';
  }

  @override
  void dispose() {
    _streetCtrl.dispose();
    _numberCtrl.dispose();
    _complementCtrl.dispose();
    _districtCtrl.dispose();
    _zipCodeCtrl.dispose();
    super.dispose();
  }

  /// Preenche os campos com o endereço resolvido pelo mapa (reverse ou
  /// autocomplete). Só sobrescreve o que veio preenchido.
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

  Future<bool> _confirmSaveWithoutCoordinates() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        title: const Text('Endereço fora do mapa'),
        content: const Text(
          'Não conseguimos localizar esse endereço no mapa. Salvar assim '
          'mesmo? Vamos tentar localizá-lo automaticamente depois.',
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_marker == null) {
      final confirmed = await _confirmSaveWithoutCoordinates();
      if (!confirmed || !mounted) return;
    }
    Navigator.of(context).pop(
      ChildAddress(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final citiesAsync = ref.watch(citiesCatalogProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Novo endereço',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.lg),
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
                      'Selecione cidade e UF para localizar o endereço no mapa.',
                  icon: Icons.map_outlined,
                  color: AppColors.slate,
                )
              else
                AddressMapPicker(
                  cityBias: _cityBias,
                  initialPosition: _marker,
                  initialLabel: _resolvedLabel,
                  height: 260,
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
                controller: _streetCtrl,
                decoration: const InputDecoration(
                  labelText: 'Rua',
                  prefixIcon: Icon(Icons.signpost_outlined),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Rua e obrigatoria.' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
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
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'CEP e obrigatorio.' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Salvar endereço'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnrollmentSection extends StatelessWidget {
  const _EnrollmentSection({
    required this.enrollmentAsync,
    this.onCancelEnrollment,
  });

  final AsyncValue<Enrollment?> enrollmentAsync;
  final ValueChanged<Enrollment>? onCancelEnrollment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FaixaSectionCard(
      icon: Icons.fact_check_rounded,
      title: 'Matrícula e transporte',
      child: enrollmentAsync.when(
        loading: () => const SizedBox(
          height: 40,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => AppInfoBanner(
          message: AppErrorReporter.messageFor(error),
          icon: Icons.error_outline_rounded,
          color: AppColors.danger,
        ),
        data: (enrollment) {
          if (enrollment == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sem matrícula ativa',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.slate,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const StatusPill(
                  label: 'Aguardando vínculo com motorista',
                  color: AppColors.warning,
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                icon: Icons.person_outline_rounded,
                label: 'Motorista',
                value: enrollment.driverName,
              ),
              const SizedBox(height: AppSpacing.sm),
              _InfoRow(
                icon: Icons.directions_car_rounded,
                label: 'Van',
                value: enrollment.vanPlate,
              ),
              const SizedBox(height: AppSpacing.sm),
              _InfoRow(
                icon: Icons.school_rounded,
                label: 'Escola',
                value: enrollment.schoolName,
              ),
              const SizedBox(height: AppSpacing.md),
              StatusPill.fromStatus(enrollment.status),
              if (enrollment.status == EnrollmentStatus.active &&
                  onCancelEnrollment != null) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  onPressed: () => onCancelEnrollment!(enrollment),
                  icon: const Icon(Icons.cancel_rounded),
                  label: const Text('Cancelar matrícula'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Editar'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.surface,
            ),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Excluir'),
          ),
        ),
      ],
    );
  }
}
