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
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 100,
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
    final relative = ((item['relative'] as Map?)?['name'] ??
            (item['relative'] as Map?)?['relative'])
        ?.toString();
    final shift = ((item['shift'] as Map?)?['shift_name'] ??
            (item['shift'] as Map?)?['name'])
        ?.toString();
    final isInadimplent = item['is_inadimplent'] == true;
    final avatarUrl =
        (item['avatar_url'] ?? item['avatar'])?.toString();
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
                        [
                          ?school,
                          ?shift,
                        ].join(' · '),
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _editChild(context, ref, item);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
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
                          icon: const Icon(Icons.photo_library_outlined,
                              size: 18),
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
                decoration:
                    const InputDecoration(labelText: 'Sexo (opcional)'),
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('Masculino')),
                  DropdownMenuItem(value: 'F', child: Text('Feminino')),
                  DropdownMenuItem(value: 'O', child: Text('Outro')),
                ],
                onChanged:
                    _saving ? null : (v) => setState(() => _sex = v),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Idade (opcional)'),
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
                Text(_error!,
                    style: TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _saving ? null : () => Navigator.of(context).pop(false),
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
          .map((i) => DropdownMenuItem(
                value: i,
                child: Text(i.name, overflow: TextOverflow.ellipsis),
              ))
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
      final id = ((c['relative'] as Map?)?['id'] as num?)?.toInt() ??
          (c['relative_id'] as num?)?.toInt();
      if (id != null) _relative = _find(rels, id);
    }
    if (_school == null && c != null) {
      final id = ((c['school'] as Map?)?['id'] as num?)?.toInt() ??
          (c['school_id'] as num?)?.toInt();
      if (id != null) _school = _find(schools, id);
    }
    if (_shift == null && c != null) {
      final id = ((c['shift'] as Map?)?['id'] as num?)?.toInt() ??
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
      await widget.onSubmit(_DependentFormDraft(
        name: name,
        relativeId: _relative!.id,
        schoolId: _school!.id,
        shiftId: _shift!.id,
        sex: _sex,
        age: age,
        avatarImagePath: _avatarPath,
      ));
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
