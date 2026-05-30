import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/models/catalog_option.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../../catalog/data/catalog_repository.dart';
import '../providers/driver_portal_providers.dart';

class DriverAddChildArgs {
  const DriverAddChildArgs({required this.clientId, required this.clientName});

  final int clientId;
  final String clientName;
}

class DriverAddChildPage extends ConsumerStatefulWidget {
  const DriverAddChildPage({super.key, required this.args});

  final DriverAddChildArgs args;

  @override
  ConsumerState<DriverAddChildPage> createState() => _DriverAddChildPageState();
}

class _DriverAddChildPageState extends ConsumerState<DriverAddChildPage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final List<_ChildAddressDraft> _addresses = [_ChildAddressDraft()];
  final _picker = ImagePicker();

  CatalogOption? _relative;
  CatalogOption? _school;
  CatalogOption? _shift;
  String? _sex;
  String? _avatarLocalPath;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    for (final address in _addresses) {
      address.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final relatives = ref.watch(relativesCatalogProvider);
    final schools = ref.watch(schoolsCatalogProvider);
    final shifts = ref.watch(shiftsCatalogProvider);
    final districts = ref.watch(districtsCatalogProvider);
    final profileAsync = ref.watch(driverProfileProvider);

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
      appBar: AppBar(title: const Text('Cadastrar dependente')),
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
                      'Cliente: ${widget.args.clientName}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da crianca',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _sex,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Sexo (opcional)',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'M',
                                child: Text('Masculino'),
                              ),
                              DropdownMenuItem(
                                value: 'F',
                                child: Text('Feminino'),
                              ),
                              DropdownMenuItem(
                                value: 'O',
                                child: Text('Outro'),
                              ),
                            ],
                            onChanged: _submitting
                                ? null
                                : (value) => setState(() => _sex = value),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Idade (opcional)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFFFF1BE),
                          backgroundImage: _avatarLocalPath != null
                              ? FileImage(File(_avatarLocalPath!))
                              : null,
                          child: _avatarLocalPath == null
                              ? const Icon(Icons.photo_camera_back_outlined)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _submitting ? null : _pickChildPhoto,
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Adicionar foto'),
                              ),
                              if (_avatarLocalPath != null)
                                TextButton.icon(
                                  onPressed: _submitting
                                      ? null
                                      : () => setState(
                                          () => _avatarLocalPath = null,
                                        ),
                                  icon: const Icon(Icons.undo_rounded),
                                  label: const Text('Remover'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _CatalogDropdown(
                      label: 'Parentesco',
                      optionsAsync: relatives,
                      selected: _relative,
                      emptyMessage: 'Nenhum parentesco disponivel.',
                      onChanged: (value) => setState(() => _relative = value),
                    ),
                    const SizedBox(height: 12),
                    _CatalogDropdown(
                      label: 'Escola',
                      optionsAsync: filteredSchools,
                      selected: _school,
                      emptyMessage: 'Nenhuma escola disponivel.',
                      onChanged: (value) => setState(() => _school = value),
                    ),
                    const SizedBox(height: 12),
                    _CatalogDropdown(
                      label: 'Turno',
                      optionsAsync: shifts,
                      selected: _shift,
                      emptyMessage: 'Nenhum turno disponivel.',
                      onChanged: (value) => setState(() => _shift = value),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Enderecos da crianca',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _submitting ? null : _addAddress,
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: const Text('Adicionar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_addresses.length, (index) {
                      final address = _addresses[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == _addresses.length - 1 ? 0 : 12,
                        ),
                        child: _ChildAddressCard(
                          index: index,
                          draft: address,
                          districtsAsync: filteredDistricts,
                          canRemove: _addresses.length > 1,
                          onRemove: _submitting
                              ? null
                              : () => _removeAddress(index),
                          onChanged: () => setState(() {}),
                          onCepChanged: (value) =>
                              _handleCepChanged(index, value),
                          onLookupCep: _submitting
                              ? null
                              : () => _lookupViaCep(index),
                        ),
                      );
                    }),
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
                          : const Icon(Icons.child_care_rounded),
                      label: Text(_submitting ? 'Salvando...' : 'Salvar dependente'),
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

  void _addAddress() {
    setState(() {
      _addresses.add(
        _ChildAddressDraft(isDefault: _addresses.every((a) => !a.isDefault)),
      );
    });
  }

  void _removeAddress(int index) {
    if (_addresses.length <= 1) return;
    final removed = _addresses.removeAt(index);
    removed.dispose();
    if (_addresses.every((a) => !a.isDefault)) {
      _addresses.first.isDefault = true;
    }
    setState(() {});
  }

  void _handleCepChanged(int index, String rawValue) {
    final cep = rawValue.replaceAll(RegExp(r'\D'), '');
    final draft = _addresses[index];
    if (cep.length == 8) {
      _lookupViaCep(index);
    } else if (draft.cepInfo != null) {
      setState(() => draft.cepInfo = null);
    }
  }

  Future<void> _lookupViaCep(int index) async {
    if (!mounted || index < 0 || index >= _addresses.length) return;
    final draft = _addresses[index];
    final cep = draft.zipcodeController.text.replaceAll(RegExp(r'\D'), '');
    if (draft.lookingUpCep || cep.length != 8) return;

    setState(() {
      draft.lookingUpCep = true;
      draft.cepInfo = null;
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
        setState(() => draft.cepInfo = 'CEP nao encontrado no ViaCEP.');
        return;
      }

      final street = (data['logradouro'] ?? '').toString().trim();
      final neighborhood = (data['bairro'] ?? '').toString().trim();
      final city = (data['localidade'] ?? '').toString().trim();
      final uf = (data['uf'] ?? '').toString().trim();
      final complement = (data['complemento'] ?? '').toString().trim();

      if (street.isNotEmpty) {
        draft.streetController.text = street;
      }
      if (complement.isNotEmpty &&
          draft.referenceController.text.trim().isEmpty) {
        draft.referenceController.text = complement;
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
          draft.district = matched;
        }
      }

      setState(() {
        draft.cepInfo = [
          if (neighborhood.isNotEmpty) neighborhood,
          if (city.isNotEmpty || uf.isNotEmpty)
            [city, uf].where((e) => e.isNotEmpty).join('/'),
        ].join(' • ');
      });
    } catch (_) {
      setState(() => draft.cepInfo = 'Falha ao consultar ViaCEP.');
    } finally {
      if (mounted) {
        setState(() => draft.lookingUpCep = false);
      }
    }
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

  String? _validateAddressDrafts() {
    if (_addresses.isEmpty) {
      return 'Adicione pelo menos um endereco para a crianca.';
    }

    for (var i = 0; i < _addresses.length; i++) {
      final address = _addresses[i];
      final zip = address.zipcodeController.text.trim();
      final street = address.streetController.text.trim();
      final number = address.numberController.text.trim();

      if (zip.isEmpty || street.isEmpty || number.isEmpty) {
        return 'Preencha CEP, rua e numero no endereco ${i + 1}.';
      }
      if (address.type.isEmpty) {
        return 'Selecione o tipo do endereco ${i + 1}.';
      }
    }

    return null;
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nome da crianca e obrigatorio.');
      return;
    }
    if (_relative == null) {
      setState(() => _error = 'Selecione o parentesco.');
      return;
    }
    if (_school == null) {
      setState(() => _error = 'Selecione a escola da crianca.');
      return;
    }
    if (_shift == null) {
      setState(() => _error = 'Selecione o turno da crianca.');
      return;
    }
    final addressesError = _validateAddressDrafts();
    if (addressesError != null) {
      setState(() => _error = addressesError);
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
      final parsedAge = int.tryParse(_ageController.text.trim());
      final child = await ref
          .read(driverPortalRepositoryProvider)
          .createChild(
            auth,
            clientId: widget.args.clientId,
            name: name,
            relativeId: _relative!.id,
            sex: _sex,
            age: parsedAge,
            avatarImagePath: _avatarLocalPath,
            schoolId: _school?.id,
            shiftId: _shift?.id,
          );

      final childId = (child['id'] as num?)?.toInt();
      if (childId == null || childId <= 0) {
        throw ApiException(
          message: 'Filho criado, mas o ID nao foi retornado.',
        );
      }

      final explicitDefaultIndex = _addresses.indexWhere((a) => a.isDefault);
      final defaultIndex = explicitDefaultIndex >= 0 ? explicitDefaultIndex : 0;
      for (var i = 0; i < _addresses.length; i++) {
        final address = _addresses[i];
        await ref
            .read(driverPortalRepositoryProvider)
            .createChildAddress(
              auth,
              childId: childId,
              zipcode: address.zipcodeController.text.trim(),
              street: address.streetController.text.trim(),
              number: address.numberController.text.trim(),
              reference: address.referenceController.text.trim(),
              districtId: address.district?.id,
              type: address.type,
              isDefault: i == defaultIndex,
            );
      }

      ref.invalidate(driverClientsProvider);
      ref.invalidate(driverClientChildrenProvider(widget.args.clientId));
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
        _error = 'Falha ao cadastrar dependente.';
      });
    }
  }

  Future<void> _pickChildPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );
    if (file == null || !mounted) return;
    setState(() => _avatarLocalPath = file.path);
  }
}

class _ChildAddressCard extends StatelessWidget {
  const _ChildAddressCard({
    required this.index,
    required this.draft,
    required this.districtsAsync,
    required this.canRemove,
    required this.onChanged,
    required this.onCepChanged,
    required this.onLookupCep,
    this.onRemove,
  });

  final int index;
  final _ChildAddressDraft draft;
  final AsyncValue<List<CatalogOption>> districtsAsync;
  final bool canRemove;
  final VoidCallback onChanged;
  final ValueChanged<String> onCepChanged;
  final VoidCallback? onLookupCep;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Endereco ${index + 1}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (canRemove)
                IconButton(
                  tooltip: 'Remover endereco',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          TextField(
            controller: draft.zipcodeController,
            keyboardType: TextInputType.number,
            onChanged: onCepChanged,
            decoration: InputDecoration(
              labelText: 'CEP',
              suffixIcon: draft.lookingUpCep
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      onPressed: onLookupCep,
                      icon: const Icon(Icons.search_rounded),
                    ),
            ),
          ),
          if (draft.cepInfo != null) ...[
            const SizedBox(height: 6),
            Text(draft.cepInfo!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: draft.streetController,
            decoration: const InputDecoration(labelText: 'Rua'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.numberController,
                  decoration: const InputDecoration(labelText: 'Numero'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: draft.type,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'home', child: Text('Casa')),
                    DropdownMenuItem(value: 'other', child: Text('Outro')),
                    DropdownMenuItem(value: 'school', child: Text('Escola')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    draft.type = value;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: draft.referenceController,
            decoration: const InputDecoration(
              labelText: 'Referencia (opcional)',
            ),
          ),
          const SizedBox(height: 10),
          _CatalogDropdown(
            label: 'Bairro (opcional)',
            optionsAsync: districtsAsync,
            selected: draft.district,
            emptyMessage: 'Nenhum bairro disponivel.',
            onChanged: (value) {
              draft.district = value;
              onChanged();
            },
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Endereco padrao'),
            value: draft.isDefault,
            onChanged: (value) {
              draft.isDefault = value;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

class _CatalogDropdown extends StatelessWidget {
  const _CatalogDropdown({
    required this.label,
    required this.optionsAsync,
    required this.selected,
    required this.onChanged,
    this.emptyMessage,
  });

  final String label;
  final AsyncValue<List<CatalogOption>> optionsAsync;
  final CatalogOption? selected;
  final ValueChanged<CatalogOption?> onChanged;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final items = optionsAsync.value ?? const <CatalogOption>[];
    final errorText = optionsAsync.hasError
        ? 'Falha ao carregar opcoes.'
        : (items.isEmpty && !optionsAsync.isLoading ? emptyMessage : null);

    return DropdownButtonFormField<CatalogOption>(
      initialValue: selected,
      isExpanded: true,
      menuMaxHeight: 320,
      decoration: InputDecoration(labelText: label, helperText: errorText),
      items: items
          .map(
            (item) => DropdownMenuItem<CatalogOption>(
              value: item,
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(growable: false),
      onChanged: optionsAsync.isLoading ? null : onChanged,
    );
  }
}

class _ChildAddressDraft {
  _ChildAddressDraft({this.isDefault = false});

  final zipcodeController = TextEditingController();
  final streetController = TextEditingController();
  final numberController = TextEditingController();
  final referenceController = TextEditingController();

  CatalogOption? district;
  String type = 'home';
  bool isDefault;
  bool lookingUpCep = false;
  String? cepInfo;

  void dispose() {
    zipcodeController.dispose();
    streetController.dispose();
    numberController.dispose();
    referenceController.dispose();
  }
}
