import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/catalog_option.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../../catalog/data/catalog_repository.dart';
import '../providers/parent_portal_providers.dart';

class ParentChildrenPage extends ConsumerWidget {
  const ParentChildrenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(parentChildrenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dependentes'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => ref.invalidate(parentChildrenProvider),
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.child_care_outlined, size: 20),
        label: const Text('Adicionar'),
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(parentChildrenProvider),
        ),
        data: (page) {
          if (page.items.isEmpty) {
            return const AppEmptyState(
              message: 'Nenhum dependente encontrado.',
              icon: Icons.child_care_outlined,
              subtitle: 'Adicione um dependente para comecar.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              100,
            ),
            itemCount: page.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) =>
                _ChildCard(item: page.items[index]),
          );
        },
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? current,
  }) async {
    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DependentFormDialog(
        current: current,
        onSubmit: (draft) async {
          final repo = ref.read(parentPortalRepositoryProvider);
          if (current == null) {
            await repo.createDependent(
              session.authorizationHeader,
              name: draft.name,
              relativeId: draft.relativeId,
              schoolId: draft.schoolId,
              shiftId: draft.shiftId,
              sex: draft.sex,
              age: draft.age,
              avatarImagePath: draft.avatarImagePath,
            );
          } else {
            final id = (current['id'] as num?)?.toInt() ?? 0;
            await repo.updateDependent(
              session.authorizationHeader,
              id,
              name: draft.name,
              relativeId: draft.relativeId,
              schoolId: draft.schoolId,
              shiftId: draft.shiftId,
              sex: draft.sex,
              age: draft.age,
              avatarImagePath: draft.avatarImagePath,
            );
          }
        },
      ),
    );
    if (result == true) ref.invalidate(parentChildrenProvider);
  }
}

// ─────────────────────────────────────────────
// Child Card
// ─────────────────────────────────────────────

class _ChildCard extends ConsumerWidget {
  const _ChildCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = (item['name'] ?? 'Sem nome').toString();
    final school = (item['school'] as Map?)?['name']?.toString();
    final relative =
        ((item['relative'] as Map?)?['name'] ??
                (item['relative'] as Map?)?['relative'])
            ?.toString();
    final shift =
        ((item['shift'] as Map?)?['shift_name'] ??
                (item['shift'] as Map?)?['name'])
            ?.toString();
    final isInadimplent = item['is_inadimplent'] == true;
    final avatarUrl = (item['avatar_url'] ?? item['avatar'])?.toString();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(url: avatarUrl, name: name),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (school != null || shift != null)
                      Text(
                        [?school, ?shift].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.slate,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (relative != null && relative.isNotEmpty)
                AppInfoPill(
                  icon: Icons.family_restroom_rounded,
                  text: relative,
                ),
              if (isInadimplent)
                const AppInfoPill(
                  icon: Icons.warning_amber_rounded,
                  text: 'Inadimplente',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SizedBox(
                width: 132,
                child: OutlinedButton.icon(
                  onPressed: () => _openAddresses(context, ref, item),
                  icon: const Icon(Icons.home_work_outlined, size: 18),
                  label: const Text('Enderecos'),
                ),
              ),
              SizedBox(
                width: 108,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _editChild(context, ref, item);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                ),
              ),
              SizedBox(
                width: 112,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, ref),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Excluir'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editChild(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> current,
  ) async {
    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DependentFormDialog(
        current: current,
        onSubmit: (draft) async {
          final repo = ref.read(parentPortalRepositoryProvider);
          final id = (current['id'] as num?)?.toInt() ?? 0;
          await repo.updateDependent(
            session.authorizationHeader,
            id,
            name: draft.name,
            relativeId: draft.relativeId,
            schoolId: draft.schoolId,
            shiftId: draft.shiftId,
            sex: draft.sex,
            age: draft.age,
            avatarImagePath: draft.avatarImagePath,
          );
        },
      ),
    );
    if (result == true) ref.invalidate(parentChildrenProvider);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final id = (item['id'] as num?)?.toInt() ?? 0;
    if (id <= 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir dependente'),
        content: Text(
          'Deseja remover ${(item['name'] ?? 'este dependente').toString()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) return;
    try {
      await ref
          .read(parentPortalRepositoryProvider)
          .deleteDependent(session.authorizationHeader, id);
      ref.invalidate(parentChildrenProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dependente removido com sucesso.')),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openAddresses(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> dependent,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _DependentAddressesSheet(dependent: dependent),
    );
    ref.invalidate(parentChildrenProvider);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name});
  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final has = url != null && url!.trim().isNotEmpty;
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.surfaceSoft,
      backgroundImage: has ? NetworkImage(url!) : null,
      child: has
          ? null
          : Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────
// Dependent Form Dialog (kept from original)
// ─────────────────────────────────────────────

class _DependentFormDraft {
  const _DependentFormDraft({
    required this.name,
    required this.relativeId,
    required this.schoolId,
    required this.shiftId,
    this.sex,
    this.age,
    this.avatarImagePath,
  });
  final String name;
  final int relativeId;
  final int schoolId;
  final int shiftId;
  final String? sex;
  final int? age;
  final String? avatarImagePath;
}

class _DependentFormDialog extends ConsumerStatefulWidget {
  const _DependentFormDialog({required this.onSubmit, this.current});
  final Map<String, dynamic>? current;
  final Future<void> Function(_DependentFormDraft) onSubmit;

  @override
  ConsumerState<_DependentFormDialog> createState() =>
      _DependentFormDialogState();
}

class _DependentFormDialogState extends ConsumerState<_DependentFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  CatalogOption? _relative;
  CatalogOption? _school;
  CatalogOption? _shift;
  String? _sex;
  String? _avatarPath;
  bool _saving = false;
  String? _error;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final c = widget.current;
    _nameCtrl = TextEditingController(text: (c?['name'] ?? '').toString());
    final ageStr = (c?['age'] ?? '').toString();
    _ageCtrl = TextEditingController(text: ageStr == 'null' ? '' : ageStr);
    final sex = (c?['sex'] ?? '').toString().trim();
    _sex = sex.isEmpty ? null : sex;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final relsAsync = ref.watch(relativesCatalogProvider);
    final schoolsAsync = ref.watch(schoolsCatalogProvider);
    final shiftsAsync = ref.watch(shiftsCatalogProvider);
    _ensureSelections(
      relsAsync.value ?? const [],
      schoolsAsync.value ?? const [],
      shiftsAsync.value ?? const [],
    );

    return AlertDialog(
      title: Text(
        widget.current == null ? 'Novo dependente' : 'Editar dependente',
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.surfaceSoft,
                    backgroundImage: _avatarPath != null
                        ? FileImage(File(_avatarPath!))
                        : null,
                    child: _avatarPath == null
                        ? const Icon(Icons.photo_camera_back_outlined)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _pickImage,
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            size: 18,
                          ),
                          label: const Text('Foto'),
                        ),
                        if (_avatarPath != null)
                          TextButton(
                            onPressed: _saving
                                ? null
                                : () => setState(() => _avatarPath = null),
                            child: const Text('Remover'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _sex,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Sexo (opcional)'),
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('Masculino')),
                  DropdownMenuItem(value: 'F', child: Text('Feminino')),
                  DropdownMenuItem(value: 'O', child: Text('Outro')),
                ],
                onChanged: _saving ? null : (v) => setState(() => _sex = v),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Idade (opcional)',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _catDropdown(
                label: 'Parentesco',
                items: relsAsync.value ?? const [],
                value: _relative,
                onChanged: (v) => setState(() => _relative = v),
              ),
              const SizedBox(height: AppSpacing.md),
              _catDropdown(
                label: 'Escola',
                items: schoolsAsync.value ?? const [],
                value: _school,
                onChanged: (v) => setState(() => _school = v),
              ),
              const SizedBox(height: AppSpacing.md),
              _catDropdown(
                label: 'Turno',
                items: shiftsAsync.value ?? const [],
                value: _shift,
                onChanged: (v) => setState(() => _shift = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }

  Widget _catDropdown({
    required String label,
    required List<CatalogOption> items,
    required CatalogOption? value,
    required ValueChanged<CatalogOption?> onChanged,
  }) {
    return DropdownButtonFormField<CatalogOption>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items
          .map(
            (i) => DropdownMenuItem(
              value: i,
              child: Text(i.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: _saving ? null : onChanged,
    );
  }

  void _ensureSelections(
    List<CatalogOption> rels,
    List<CatalogOption> schools,
    List<CatalogOption> shifts,
  ) {
    final c = widget.current;
    if (_relative == null && c != null) {
      final id =
          ((c['relative'] as Map?)?['id'] as num?)?.toInt() ??
          (c['relative_id'] as num?)?.toInt();
      if (id != null) _relative = _find(rels, id);
    }
    if (_school == null && c != null) {
      final id =
          ((c['school'] as Map?)?['id'] as num?)?.toInt() ??
          (c['school_id'] as num?)?.toInt();
      if (id != null) _school = _find(schools, id);
    }
    if (_shift == null && c != null) {
      final id =
          ((c['shift'] as Map?)?['id'] as num?)?.toInt() ??
          (c['shift_id'] as num?)?.toInt();
      if (id != null) _shift = _find(shifts, id);
    }
  }

  CatalogOption? _find(List<CatalogOption> items, int id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    setState(() => _avatarPath = file.path);
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nome e obrigatorio.');
      return;
    }
    if (_relative == null || _school == null || _shift == null) {
      setState(() => _error = 'Selecione parentesco, escola e turno.');
      return;
    }
    final ageText = _ageCtrl.text.trim();
    final age = ageText.isEmpty ? null : int.tryParse(ageText);
    if (ageText.isNotEmpty && age == null) {
      setState(() => _error = 'Idade invalida.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        _DependentFormDraft(
          name: name,
          relativeId: _relative!.id,
          schoolId: _school!.id,
          shiftId: _shift!.id,
          sex: _sex,
          age: age,
          avatarImagePath: _avatarPath,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'Falha ao salvar dependente.';
      });
    }
  }
}

class _DependentAddressesSheet extends ConsumerStatefulWidget {
  const _DependentAddressesSheet({required this.dependent});

  final Map<String, dynamic> dependent;

  @override
  ConsumerState<_DependentAddressesSheet> createState() =>
      _DependentAddressesSheetState();
}

class _DependentAddressesSheetState
    extends ConsumerState<_DependentAddressesSheet> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final name = (widget.dependent['name'] ?? 'Dependente').toString();
    final addresses = ((widget.dependent['addresses'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);

    return SizedBox(
      height: (MediaQuery.sizeOf(context).height * 0.82).clamp(440.0, 760.0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enderecos de $name',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Cadastre um ou mais enderecos para o motorista escolher ao planejar a rota.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: addresses.isEmpty
                  ? const AppEmptyState(
                      message: 'Nenhum endereco cadastrado.',
                      icon: Icons.home_outlined,
                    )
                  : ListView.separated(
                      itemCount: addresses.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final item = addresses[index];
                        final district = (item['district'] as Map?)?['name']
                            ?.toString();
                        final city = (item['city'] as Map?)?['name']
                            ?.toString();
                        final type = (item['type'] ?? 'home').toString();
                        final isDefault = item['is_default'] == true;
                        final label = [
                          (item['street'] ?? '').toString(),
                          (item['number'] ?? '').toString(),
                        ].where((e) => e.trim().isNotEmpty).join(', ');
                        final extra = [
                          ?district,
                          ?city,
                        ].where((e) => e.trim().isNotEmpty).join(' · ');
                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      label.isEmpty ? 'Endereco' : label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  if (isDefault)
                                    const AppInfoPill(
                                      icon: Icons.check_circle_outline_rounded,
                                      text: 'Padrao',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_addressTypeLabel(type)}${extra.isEmpty ? '' : ' · $extra'}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.slate),
                              ),
                              if ((item['reference'] ?? '')
                                  .toString()
                                  .trim()
                                  .isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Ref: ${(item['reference'] ?? '').toString()}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppColors.slate),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _saving
                                      ? null
                                      : () => _openAddressForm(current: item),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Editar'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saving ? null : () => _openAddressForm(),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Adicionar endereco'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddressForm({Map<String, dynamic>? current}) async {
    final draft = await showDialog<_DependentAddressDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DependentAddressDialog(current: current),
    );
    if (draft == null || !mounted) return;
    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) return;
    final dependentId = (widget.dependent['id'] as num?)?.toInt() ?? 0;
    if (dependentId <= 0) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(parentPortalRepositoryProvider);
      if (current == null) {
        await repo.createDependentAddress(
          session.authorizationHeader,
          dependentId: dependentId,
          zipcode: draft.zipcode,
          street: draft.street,
          number: draft.number,
          reference: draft.reference,
          districtId: draft.districtId,
          cityId: draft.cityId,
          type: draft.type,
          isDefault: draft.isDefault,
          latitude: draft.latitude,
          longitude: draft.longitude,
        );
      } else {
        final addressId = (current['id'] as num?)?.toInt() ?? 0;
        if (addressId <= 0) return;
        await repo.updateDependentAddress(
          session.authorizationHeader,
          dependentId: dependentId,
          addressId: addressId,
          zipcode: draft.zipcode,
          street: draft.street,
          number: draft.number,
          reference: draft.reference,
          districtId: draft.districtId,
          cityId: draft.cityId,
          type: draft.type,
          isDefault: draft.isDefault,
          latitude: draft.latitude,
          longitude: draft.longitude,
        );
      }
      ref.invalidate(parentChildrenProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _DependentAddressDraft {
  const _DependentAddressDraft({
    required this.zipcode,
    required this.street,
    required this.number,
    required this.type,
    required this.isDefault,
    this.reference,
    this.districtId,
    this.cityId,
    this.latitude,
    this.longitude,
  });

  final String zipcode;
  final String street;
  final String number;
  final String? reference;
  final int? districtId;
  final int? cityId;
  final String type;
  final bool isDefault;
  final String? latitude;
  final String? longitude;
}

class _DependentAddressDialog extends ConsumerStatefulWidget {
  const _DependentAddressDialog({this.current});

  final Map<String, dynamic>? current;

  @override
  ConsumerState<_DependentAddressDialog> createState() =>
      _DependentAddressDialogState();
}

class _DependentAddressDialogState
    extends ConsumerState<_DependentAddressDialog> {
  late final TextEditingController _zipcodeCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _numberCtrl;
  late final TextEditingController _referenceCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  CatalogOption? _district;
  String _type = 'home';
  bool _isDefault = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.current;
    _zipcodeCtrl = TextEditingController(
      text: (c?['zipcode'] ?? '').toString(),
    );
    _streetCtrl = TextEditingController(text: (c?['street'] ?? '').toString());
    _numberCtrl = TextEditingController(text: (c?['number'] ?? '').toString());
    _referenceCtrl = TextEditingController(
      text: (c?['reference'] ?? '').toString(),
    );
    _latCtrl = TextEditingController(text: (c?['latitude'] ?? '').toString());
    _lngCtrl = TextEditingController(text: (c?['longitude'] ?? '').toString());
    final rawType = (c?['type'] ?? 'home').toString().trim();
    _type = ['home', 'school', 'other'].contains(rawType) ? rawType : 'home';
    _isDefault = c?['is_default'] == true;
  }

  @override
  void dispose() {
    _zipcodeCtrl.dispose();
    _streetCtrl.dispose();
    _numberCtrl.dispose();
    _referenceCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final districts = ref.watch(districtsCatalogProvider).value ?? const [];
    if (_district == null && widget.current != null) {
      final districtId =
          ((widget.current!['district'] as Map?)?['id'] as num?)?.toInt() ??
          (widget.current!['district_id'] as num?)?.toInt();
      if (districtId != null) {
        for (final item in districts) {
          if (item.id == districtId) {
            _district = item;
            break;
          }
        }
      }
    }

    return AlertDialog(
      title: Text(widget.current == null ? 'Novo endereco' : 'Editar endereco'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _zipcodeCtrl,
                decoration: const InputDecoration(labelText: 'CEP'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _streetCtrl,
                decoration: const InputDecoration(labelText: 'Rua'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _numberCtrl,
                decoration: const InputDecoration(labelText: 'Numero'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _referenceCtrl,
                decoration: const InputDecoration(labelText: 'Referencia'),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<CatalogOption>(
                initialValue: _district,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Bairro'),
                items: districts
                    .map(
                      (d) => DropdownMenuItem<CatalogOption>(
                        value: d,
                        child: Text(d.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (v) => setState(() => _district = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: 'home', child: Text('Casa')),
                  DropdownMenuItem(value: 'school', child: Text('Escola')),
                  DropdownMenuItem(value: 'other', child: Text('Outro')),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'home'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latCtrl,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _lngCtrl,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                title: const Text('Definir como endereco padrao'),
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }

  void _submit() {
    final zipcode = _zipcodeCtrl.text.trim();
    final street = _streetCtrl.text.trim();
    final number = _numberCtrl.text.trim();
    if (zipcode.isEmpty || street.isEmpty || number.isEmpty) {
      setState(() => _error = 'CEP, rua e numero sao obrigatorios.');
      return;
    }
    Navigator.of(context).pop(
      _DependentAddressDraft(
        zipcode: zipcode,
        street: street,
        number: number,
        reference: _referenceCtrl.text.trim().isEmpty
            ? null
            : _referenceCtrl.text.trim(),
        districtId: _district?.id,
        cityId: null,
        type: _type,
        isDefault: _isDefault,
        latitude: _latCtrl.text.trim().isEmpty ? null : _latCtrl.text.trim(),
        longitude: _lngCtrl.text.trim().isEmpty ? null : _lngCtrl.text.trim(),
      ),
    );
  }
}

String _addressTypeLabel(String type) {
  return switch (type.trim().toLowerCase()) {
    'home' => 'Casa',
    'school' => 'Escola',
    _ => 'Outro',
  };
}
