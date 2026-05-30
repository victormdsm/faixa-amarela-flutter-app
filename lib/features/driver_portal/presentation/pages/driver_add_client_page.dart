import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/models/catalog_option.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../../catalog/data/catalog_repository.dart';
import '../providers/driver_portal_providers.dart';

class DriverAddClientPage extends ConsumerStatefulWidget {
  const DriverAddClientPage({super.key});

  @override
  ConsumerState<DriverAddClientPage> createState() =>
      _DriverAddClientPageState();
}

class _DriverAddClientPageState extends ConsumerState<DriverAddClientPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cellPhoneController = TextEditingController();
  final _zipcodeController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _referenceController = TextEditingController();

  CatalogOption? _school;
  CatalogOption? _district;
  CatalogOption? _shift;
  int? _linkedParentId;
  List<_LookupDependentOption> _lookupDependents = const [];
  _LookupDependentOption? _selectedDependent;
  bool _submitting = false;
  bool _lookingUpCep = false;
  bool _lookingUpParentCpf = false;
  String? _error;
  String? _cepInfo;
  String? _parentLookupInfo;
  String? _inadimplencyWarning;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _cellPhoneController.dispose();
    _zipcodeController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(driverProfileProvider);
    final schools = ref.watch(schoolsCatalogProvider);
    final districts = ref.watch(districtsCatalogProvider);
    final shifts = ref.watch(shiftsCatalogProvider);
    final filteredSchools = _filterByDriverProfile(
      schools,
      profileAsync,
      key: 'schools',
    );
    final filteredDistricts = _filterByDriverProfile(
      districts,
      profileAsync,
      key: 'districts',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Vincular responsavel')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'O responsavel deve realizar o proprio cadastro no app. Aqui o motorista apenas vincula o responsavel e o dependente pelo CPF.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(_nameController, 'Nome do responsavel'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _emailController,
                      'E-mail',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(_cpfController, 'CPF'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _submitting || _lookingUpParentCpf
                              ? null
                              : _lookupParentByCpf,
                          icon: _lookingUpParentCpf
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.person_search_rounded),
                          label: const Text('Buscar responsavel pelo CPF'),
                        ),
                        if (_parentLookupInfo != null)
                          Text(
                            _parentLookupInfo!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                    if (_lookupDependents.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<_LookupDependentOption>(
                        initialValue: _selectedDependent,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Dependente para vincular',
                        ),
                        items: _lookupDependents
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(
                                  item.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: _submitting
                            ? null
                            : (value) => setState(() => _selectedDependent = value),
                      ),
                    ],
                    if (_inadimplencyWarning != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4D6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE3B23C)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _inadimplencyWarning!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildTextField(_cellPhoneController, 'Telefone/WhatsApp'),
                    const SizedBox(height: 16),
                    _CatalogDropdown(
                      label: 'Escola (opcional)',
                      optionsAsync: filteredSchools,
                      selected: _school,
                      onChanged: (value) => setState(() => _school = value),
                    ),
                    const SizedBox(height: 12),
                    _CatalogDropdown(
                      label: 'Bairro (opcional)',
                      optionsAsync: filteredDistricts,
                      selected: _district,
                      onChanged: (value) => setState(() => _district = value),
                    ),
                    const SizedBox(height: 12),
                    _CatalogDropdown(
                      label: 'Turno (opcional)',
                      optionsAsync: shifts,
                      selected: _shift,
                      onChanged: (value) => setState(() => _shift = value),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Endereco principal',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _zipcodeController,
                      'CEP',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _handleCepChanged(),
                      suffix: _lookingUpCep
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              onPressed: _lookupViaCep,
                              icon: const Icon(Icons.search_rounded),
                              tooltip: 'Buscar CEP',
                            ),
                    ),
                    if (_cepInfo != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _cepInfo!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildTextField(_streetController, 'Rua'),
                    const SizedBox(height: 12),
                    _buildTextField(_numberController, 'Numero'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _referenceController,
                      'Referencia (opcional)',
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _submitting ? 'Salvando...' : 'Vincular responsavel',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    Widget? suffix,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      readOnly: readOnly,
      decoration: InputDecoration(labelText: label, suffixIcon: suffix),
    );
  }

  void _handleCepChanged() {
    final cep = _zipcodeController.text.replaceAll(RegExp(r'\D'), '');
    if (cep.length == 8) {
      _lookupViaCep();
    } else if (_cepInfo != null) {
      setState(() => _cepInfo = null);
    }
  }

  Future<void> _lookupViaCep() async {
    final cep = _zipcodeController.text.replaceAll(RegExp(r'\D'), '');
    if (_lookingUpCep || cep.length != 8) return;

    setState(() {
      _lookingUpCep = true;
      _cepInfo = null;
    });

    try {
      final response = await Dio(
        BaseOptions(
          baseUrl: 'https://viacep.com.br/ws',
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      ).get<Map<String, dynamic>>('/$cep/json/');

      final data = response.data ?? const <String, dynamic>{};
      if (data['erro'] == true) {
        setState(() => _cepInfo = 'CEP nao encontrado no ViaCEP.');
        return;
      }

      final street = (data['logradouro'] ?? '').toString().trim();
      final neighborhood = (data['bairro'] ?? '').toString().trim();
      final city = (data['localidade'] ?? '').toString().trim();
      final uf = (data['uf'] ?? '').toString().trim();
      final complement = (data['complemento'] ?? '').toString().trim();

      if (street.isNotEmpty) {
        _streetController.text = street;
      }

      if (complement.isNotEmpty && _referenceController.text.trim().isEmpty) {
        _referenceController.text = complement;
      }

      final districtOptions = _filterByDriverProfile(
        ref.read(districtsCatalogProvider),
        ref.read(driverProfileProvider),
        key: 'districts',
      ).value;
      if (districtOptions != null && neighborhood.isNotEmpty) {
        final normalizedNeighborhood = _normalizeText(neighborhood);
        final matched = districtOptions.cast<CatalogOption?>().firstWhere(
          (option) =>
              option != null &&
              _normalizeText(option.name) == normalizedNeighborhood,
          orElse: () => null,
        );
        if (matched != null) {
          _district = matched;
        }
      }

      setState(() {
        _cepInfo = [
          if (neighborhood.isNotEmpty) neighborhood,
          if (city.isNotEmpty || uf.isNotEmpty)
            [city, uf].where((e) => e.isNotEmpty).join('/'),
        ].join(' • ');
      });
    } catch (_) {
      setState(() => _cepInfo = 'Falha ao consultar ViaCEP.');
    } finally {
      if (mounted) {
        setState(() => _lookingUpCep = false);
      }
    }
  }

  Future<void> _lookupParentByCpf() async {
    final cpf = _cpfController.text.trim();
    final normalizedCpf = cpf.replaceAll(RegExp(r'\D'), '');
    if (_lookingUpParentCpf || normalizedCpf.length < 11) {
      setState(() {
        _parentLookupInfo = 'Informe um CPF valido para buscar.';
      });
      return;
    }

    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) {
      setState(() {
        _parentLookupInfo = 'Sessao expirada. Faca login novamente.';
      });
      return;
    }

    setState(() {
      _lookingUpParentCpf = true;
      _parentLookupInfo = null;
      _inadimplencyWarning = null;
    });

    try {
      final result = await ref
          .read(driverPortalRepositoryProvider)
          .lookupParentByCpf(session.authorizationHeader, cpf);

      final found = result['found'] == true;
      if (!found) {
        setState(() {
          _parentLookupInfo =
              (result['message'] ?? 'Nenhum responsavel encontrado para este CPF.')
                  .toString();
        });
        return;
      }

      final parent = (result['parent'] as Map?) ?? const {};
      final dependents = ((result['dependents'] as List?) ?? const []);
      final name = (parent['name'] ?? '').toString().trim();
      final email = (parent['email'] ?? '').toString().trim();
      final cellPhone = (parent['cell_phone'] ?? '').toString().trim();
      if (name.isNotEmpty) _nameController.text = name;
      if (email.isNotEmpty) _emailController.text = email;
      if (cellPhone.isNotEmpty) _cellPhoneController.text = cellPhone;

      final linkedDependentIds = (((result['linked_dependent_ids'] as List?) ?? const [])
              .whereType<num>()
              .map((e) => e.toInt()))
          .toSet();
      final dependentOptions = dependents
          .whereType<Map>()
          .map((raw) => Map<String, dynamic>.from(raw))
          .map(
            (raw) => _LookupDependentOption(
              id: (raw['id'] as num?)?.toInt() ?? 0,
              blockedByOtherDriver: raw['linked_to_other_driver'] == true,
              label: [
                (raw['name'] ?? 'Dependente').toString(),
                if ((raw['school_name'] ?? '').toString().isNotEmpty)
                  'Escola: ${raw['school_name']}',
                if ((raw['shift_name'] ?? '').toString().isNotEmpty)
                  'Turno: ${raw['shift_name']}',
                if (raw['is_inadimplent'] == true) 'INADIMPLENTE',
                if (linkedDependentIds.contains((raw['id'] as num?)?.toInt() ?? 0))
                  'ja vinculado a este motorista',
                if (raw['linked_to_other_driver'] == true)
                  (() {
                    final rawNames =
                        (raw['linked_other_driver_names'] as List?) ??
                        const [];
                    final names = rawNames
                        .map((name) => name.toString().trim())
                        .where((name) => name.isNotEmpty)
                        .toList(growable: false);
                    if (names.isNotEmpty) {
                      return 'vinculado a outro motorista (${names.join(', ')})';
                    }
                    return 'vinculado a outro motorista';
                  })(),
              ].join(' • '),
            ),
          )
          .where((item) => item.id > 0)
          .toList(growable: false);

      final alreadyLinked = result['already_linked_to_driver'] == true;
      final hasDebtAlert = result['inadimplency_alert'] == true;
      final inadimplency = (result['inadimplency'] as Map?) ?? const {};
      final debtAmount = inadimplency['amount'];
      final debtReason = (inadimplency['reason'] ?? '').toString().trim();
      final firstAvailableDependent = dependentOptions
          .where((item) => !item.blockedByOtherDriver)
          .toList(growable: false);
      setState(() {
        _linkedParentId = (parent['id'] as num?)?.toInt();
        _lookupDependents = dependentOptions;
        _selectedDependent = firstAvailableDependent.isNotEmpty
            ? firstAvailableDependent.first
            : (dependentOptions.isNotEmpty ? dependentOptions.first : null);
        _parentLookupInfo = alreadyLinked
            ? 'Responsavel encontrado (ja vinculado a este motorista).'
            : 'Responsavel encontrado. Dados preenchidos.';
        if (dependentOptions.isEmpty) {
          _parentLookupInfo =
              'Responsavel encontrado, mas sem dependentes cadastrados. O responsavel deve cadastrar o dependente no app.';
        } else if (dependentOptions.every((item) => item.blockedByOtherDriver)) {
          _parentLookupInfo =
              'Responsavel encontrado, mas todos os dependentes ativos ja estao vinculados a outro motorista.';
        }
        if (hasDebtAlert) {
          _inadimplencyWarning = [
            'Atencao: este responsavel/dependente possui debitos.',
            if (debtAmount != null) 'Valor: R\$ $debtAmount',
            if (debtReason.isNotEmpty) 'Motivo: $debtReason',
          ].join(' ');
        }
      });
    } on ApiException catch (e) {
      setState(() => _parentLookupInfo = e.message);
    } catch (_) {
      setState(() => _parentLookupInfo = 'Falha ao buscar o responsavel.');
    } finally {
      if (mounted) {
        setState(() => _lookingUpParentCpf = false);
      }
    }
  }

  String _normalizeText(String value) {
    final lower = value.toLowerCase().trim();
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    var result = lower;
    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result;
  }

  AsyncValue<List<CatalogOption>> _filterByDriverProfile(
    AsyncValue<List<CatalogOption>> source,
    AsyncValue<Map<String, dynamic>> profileAsync, {
    required String key,
  }) {
    final allowedIds = _driverAllowedIds(profileAsync, key: key);
    if (allowedIds == null) return source;

    final options = source.value;
    if (options == null) return source;

    final filtered = options
        .where((option) => allowedIds.contains(option.id))
        .toList(growable: false);

    return AsyncValue.data(filtered);
  }

  Set<int>? _driverAllowedIds(
    AsyncValue<Map<String, dynamic>> profileAsync, {
    required String key,
  }) {
    final profile = profileAsync.value;
    if (profile == null) return null;

    final rawList = profile[key];
    if (rawList is! List) return null;

    return rawList
        .whereType<Map>()
        .map((item) => (item['id'] as num?)?.toInt() ?? 0)
        .where((id) => id > 0)
        .toSet();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final cpf = _cpfController.text.trim();
    final zipcode = _zipcodeController.text.trim();
    final street = _streetController.text.trim();
    final number = _numberController.text.trim();

    final nameError = name.isEmpty ? 'Nome e obrigatorio.' : null;
    final emailError = Validators.email(email);
    final cpfError = cpf.isEmpty ? 'CPF e obrigatorio.' : null;
    final zipError = zipcode.isEmpty ? 'CEP e obrigatorio.' : null;
    final streetError = street.isEmpty ? 'Rua e obrigatoria.' : null;
    final numberError = number.isEmpty ? 'Numero e obrigatorio.' : null;

    final error =
        nameError ??
        emailError ??
        cpfError ??
        zipError ??
        streetError ??
        numberError;
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    if (_linkedParentId == null) {
      setState(() {
        _error =
            'Busque um responsavel existente pelo CPF. O cadastro do responsavel e feito pelo proprio app.';
      });
      return;
    }
    if (_selectedDependent == null) {
      setState(() => _error = 'Selecione o dependente que sera vinculado a esta van.');
      return;
    }
    if (_selectedDependent!.blockedByOtherDriver) {
      setState(() {
        _error =
            'Este dependente ja esta vinculado a outro motorista. Selecione outro dependente.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final session = ref.read(appSessionControllerProvider).session;
      if (session == null) {
        throw ApiException(message: 'Sessao expirada. Faca login novamente.');
      }
      final auth = session.authorizationHeader;
      await ref
          .read(driverPortalRepositoryProvider)
          .createClient(
            auth,
            parentId: _linkedParentId,
            childId: _selectedDependent?.id,
            name: name,
            email: email,
            cpf: cpf,
            cellPhone: _cellPhoneController.text.trim(),
            schoolId: _school?.id,
            districtId: _district?.id,
            shiftId: _shift?.id,
            zipcode: zipcode,
            street: street,
            number: number,
            reference: _referenceController.text.trim(),
          );

      ref.invalidate(driverClientsProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _submitting = false;
        _error = 'Falha ao vincular responsavel.';
      });
    }
  }
}

class _LookupDependentOption {
  const _LookupDependentOption({
    required this.id,
    required this.label,
    required this.blockedByOtherDriver,
  });

  final int id;
  final String label;
  final bool blockedByOtherDriver;
}

class _CatalogDropdown extends StatelessWidget {
  const _CatalogDropdown({
    required this.label,
    required this.optionsAsync,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final AsyncValue<List<CatalogOption>> optionsAsync;
  final CatalogOption? selected;
  final ValueChanged<CatalogOption?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = optionsAsync.value ?? const <CatalogOption>[];
    return DropdownButtonFormField<CatalogOption?>(
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      selectedItemBuilder: (context) {
        return [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Nao selecionar',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          ...options.map(
            (item) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ];
      },
      items: [
        const DropdownMenuItem<CatalogOption?>(
          value: null,
          child: Text(
            'Nao selecionar',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        ...options.map(
          (item) => DropdownMenuItem<CatalogOption?>(
            value: item,
            child: Text(
              item.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ],
      onChanged: optionsAsync.isLoading ? null : onChanged,
    );
  }
}
