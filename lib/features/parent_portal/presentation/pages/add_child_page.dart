import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/catalog_option.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../domain/models/child.dart';
import '../../../../features/catalog/data/catalog_repository.dart';
import '../providers/parent_portal_providers.dart';
import '../state/add_child_controller.dart';

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
  late final TextEditingController _birthDateCtrl;
  late final TextEditingController _schoolNameCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _numberCtrl;
  late final TextEditingController _complementCtrl;
  late final TextEditingController _neighborhoodCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _zipCodeCtrl;

  CatalogOption? _shift;
  DateTime? _birthDate;

  bool get _isEditing => widget.childToEdit != null;

  @override
  void initState() {
    super.initState();
    final c = widget.childToEdit;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _cpfCtrl = TextEditingController(text: c?.cpf ?? '');
    _schoolNameCtrl = TextEditingController(text: c?.schoolName ?? '');
    _streetCtrl = TextEditingController(text: c?.address.street ?? '');
    _numberCtrl = TextEditingController(text: c?.address.number ?? '');
    _complementCtrl = TextEditingController(text: c?.address.complement ?? '');
    _neighborhoodCtrl = TextEditingController(
      text: c?.address.neighborhood ?? '',
    );
    _cityCtrl = TextEditingController(text: c?.address.city ?? '');
    _stateCtrl = TextEditingController(text: c?.address.state ?? '');
    _zipCodeCtrl = TextEditingController(text: c?.address.zipCode ?? '');
    _birthDate = c?.birthDate;
    _birthDateCtrl = TextEditingController(
      text: c?.birthDate != null ? _formatDate(c!.birthDate!) : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cpfCtrl.dispose();
    _birthDateCtrl.dispose();
    _schoolNameCtrl.dispose();
    _streetCtrl.dispose();
    _numberCtrl.dispose();
    _complementCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCodeCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 5, now.month, now.day),
      firstDate: DateTime(1990),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateCtrl.text = _formatDate(picked);
      });
    }
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a data de nascimento.')),
      );
      return;
    }
    if (_shift == null && !_isEditing) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione o turno.')));
      return;
    }

    final formData = AddChildFormData(
      name: _nameCtrl.text.trim(),
      cpf: _cpfCtrl.text.trim(),
      birthDate: _birthDate!,
      schoolName: _schoolNameCtrl.text.trim(),
      shiftId: _shift?.id ?? widget.childToEdit?.shiftId ?? 0,
      shiftName: _shift?.name ?? widget.childToEdit?.shiftName ?? '',
      address: ChildAddress(
        street: _streetCtrl.text.trim(),
        number: _numberCtrl.text.trim(),
        complement: _complementCtrl.text.trim().isEmpty
            ? null
            : _complementCtrl.text.trim(),
        neighborhood: _neighborhoodCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        zipCode: _zipCodeCtrl.text.trim(),
      ),
    );

    final controller = ref.read(addChildControllerProvider.notifier);
    final future = _isEditing
        ? controller.updateChild(widget.childToEdit!.id, formData)
        : controller.submit(formData);

    future.then((_) {
      if (!mounted) return;
      final state = ref.read(addChildControllerProvider);
      if (!state.hasError) {
        ref.read(childrenControllerProvider.notifier).refresh();
        context.pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shiftsAsync = ref.watch(shiftsCatalogProvider);
    final addState = ref.watch(addChildControllerProvider);

    // Auto-select shift when editing and catalog loads
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar dependente' : 'Novo dependente'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Dados pessoais',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome completo'),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nome e obrigatorio.' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _cpfCtrl,
              decoration: const InputDecoration(
                labelText: 'CPF',
                hintText: 'Apenas numeros',
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: _validateCpf,
              enabled: !_isEditing,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _birthDateCtrl,
              decoration: const InputDecoration(
                labelText: 'Data de nascimento',
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
              readOnly: true,
              onTap: _pickBirthDate,
              validator: (v) => v == null || v.isEmpty
                  ? 'Data de nascimento e obrigatoria.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _schoolNameCtrl,
              decoration: const InputDecoration(labelText: 'Escola'),
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Nome da escola e obrigatorio.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            _ShiftDropdown(
              shiftsAsync: shiftsAsync,
              value: _shift,
              onChanged: (v) => setState(() => _shift = v),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Endereco', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _streetCtrl,
              decoration: const InputDecoration(labelText: 'Rua'),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Rua e obrigatoria.' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _numberCtrl,
              decoration: const InputDecoration(labelText: 'Numero'),
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
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _neighborhoodCtrl,
              decoration: const InputDecoration(labelText: 'Bairro'),
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Bairro e obrigatorio.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _cityCtrl,
              decoration: const InputDecoration(labelText: 'Cidade'),
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Cidade e obrigatoria.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _stateCtrl,
              decoration: const InputDecoration(labelText: 'Estado'),
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Estado e obrigatorio.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _zipCodeCtrl,
              decoration: const InputDecoration(labelText: 'CEP'),
              textInputAction: TextInputAction.done,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'CEP e obrigatorio.' : null,
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

class _ShiftDropdown extends StatelessWidget {
  const _ShiftDropdown({
    required this.shiftsAsync,
    required this.value,
    required this.onChanged,
  });

  final AsyncValue<List<CatalogOption>> shiftsAsync;
  final CatalogOption? value;
  final ValueChanged<CatalogOption?> onChanged;

  @override
  Widget build(BuildContext context) {
    return shiftsAsync.when(
      loading: () => const InputDecorator(
        decoration: InputDecoration(labelText: 'Turno'),
        child: SizedBox(height: 20, child: LinearProgressIndicator()),
      ),
      error: (_, _) => DropdownButtonFormField<CatalogOption>(
        // ignore: deprecated_member_use
        value: value,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Turno',
          errorText: 'Erro ao carregar turnos.',
        ),
        items: const [],
        onChanged: onChanged,
      ),
      data: (shifts) => DropdownButtonFormField<CatalogOption>(
        // ignore: deprecated_member_use
        value: value,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Turno'),
        items: shifts
            .map(
              (s) => DropdownMenuItem(
                value: s,
                child: Text(s.name, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(growable: false),
        onChanged: onChanged,
        validator: (v) => v == null ? 'Selecione um turno.' : null,
      ),
    );
  }
}
