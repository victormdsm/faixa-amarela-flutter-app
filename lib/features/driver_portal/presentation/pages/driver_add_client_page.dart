import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../providers/driver_portal_providers.dart';

class DriverAddClientPage extends ConsumerStatefulWidget {
  const DriverAddClientPage({super.key});

  @override
  ConsumerState<DriverAddClientPage> createState() =>
      _DriverAddClientPageState();
}

class _DriverAddClientPageState extends ConsumerState<DriverAddClientPage> {
  final _cpfController = TextEditingController();

  bool _lookingUpCpf = false;
  bool _submitting = false;

  int? _linkedParentId;
  String? _parentInfo;
  String? _inadimplencyWarning;
  String? _error;

  List<_DepOption> _dependents = const [];
  _DepOption? _selectedDependent;

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canLink = _linkedParentId != null &&
        _selectedDependent != null &&
        !_selectedDependent!.blockedByOtherDriver;

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
                      'O responsavel deve criar a conta no app. Aqui o motorista apenas vincula pelo CPF.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.slate,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // CPF field
                    TextField(
                      controller: _cpfController,
                      keyboardType: TextInputType.number,
                      enabled: !_submitting,
                      onChanged: (_) => _resetLookup(),
                      decoration: const InputDecoration(
                        labelText: 'CPF do responsavel',
                        hintText: '000.000.000-00',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Lookup button
                    OutlinedButton.icon(
                      onPressed: (_lookingUpCpf || _submitting)
                          ? null
                          : _lookupByCpf,
                      icon: _lookingUpCpf
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_search_rounded),
                      label: const Text('Buscar responsavel pelo CPF'),
                    ),

                    // Parent info banner
                    if (_parentInfo != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          _parentInfo!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],

                    // Inadimplency warning
                    if (_inadimplencyWarning != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4D6),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: const Color(0xFFE3B23C)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFE3B23C),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _inadimplencyWarning!,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Dependent dropdown
                    if (_dependents.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<_DepOption>(
                        initialValue: _selectedDependent,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Dependente para vincular',
                        ),
                        items: _dependents
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text(
                                  d.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: _submitting
                            ? null
                            : (v) {
                                if (v == null) return;
                                if (v.blockedByOtherDriver) {
                                  setState(() {
                                    _error =
                                        'Dependente vinculado a outro motorista.';
                                  });
                                  return;
                                }
                                setState(() {
                                  _selectedDependent = v;
                                  _error = null;
                                });
                              },
                      ),
                    ],

                    // Error
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Link button
                    FilledButton.icon(
                      onPressed: (canLink && !_submitting) ? _link : null,
                      icon: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.link_rounded),
                      label: Text(_submitting ? 'Vinculando...' : 'Vincular'),
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

  void _resetLookup() {
    if (_linkedParentId != null) {
      setState(() {
        _linkedParentId = null;
        _parentInfo = null;
        _inadimplencyWarning = null;
        _dependents = const [];
        _selectedDependent = null;
        _error = null;
      });
    }
  }

  Future<void> _lookupByCpf() async {
    final cpf = _cpfController.text.trim();
    if (cpf.replaceAll(RegExp(r'\D'), '').length < 11) {
      setState(() => _error = 'Informe um CPF valido.');
      return;
    }

    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) {
      setState(() => _error = 'Sessao expirada. Faca login novamente.');
      return;
    }

    setState(() {
      _lookingUpCpf = true;
      _error = null;
      _parentInfo = null;
      _inadimplencyWarning = null;
      _linkedParentId = null;
      _dependents = const [];
      _selectedDependent = null;
    });

    try {
      final result = await ref
          .read(driverPortalRepositoryProvider)
          .lookupParentByCpf(session.authorizationHeader, cpf);

      if (result['found'] != true) {
        setState(() {
          _parentInfo = (result['message'] ??
                  'Nenhum responsavel encontrado para este CPF.')
              .toString();
        });
        return;
      }

      final parent = (result['parent'] as Map?) ?? const {};
      final dependents = (result['dependents'] as List?) ?? const [];
      final parentId = (parent['id'] as num?)?.toInt();
      final parentName = (parent['name'] ?? '').toString();
      final alreadyLinked = result['already_linked_to_driver'] == true;
      final hasDebt = result['inadimplency_alert'] == true;

      final linkedIds = ((result['linked_dependent_ids'] as List?) ?? [])
          .whereType<num>()
          .map((e) => e.toInt())
          .toSet();

      final options = dependents
          .whereType<Map>()
          .map((raw) {
            final id = (raw['id'] as num?)?.toInt() ?? 0;
            final name = (raw['name'] ?? 'Dependente').toString();
            final school = (raw['school_name'] ?? '').toString();
            final shift = (raw['shift_name'] ?? '').toString();
            final blocked = raw['linked_to_other_driver'] == true;
            final alreadyThis = linkedIds.contains(id);

            final parts = [
              name,
              if (school.isNotEmpty) school,
              if (shift.isNotEmpty) shift,
              if (alreadyThis) 'ja vinculado',
              if (blocked) 'outro motorista',
            ];

            return _DepOption(
              id: id,
              label: parts.join(' · '),
              blockedByOtherDriver: blocked,
            );
          })
          .where((d) => d.id > 0)
          .toList(growable: false);

      final firstAvailable = options
          .where((d) => !d.blockedByOtherDriver)
          .toList(growable: false);

      final inadimplency = (result['inadimplency'] as Map?) ?? const {};
      final debtAmount = inadimplency['amount'];

      setState(() {
        _linkedParentId = parentId;
        _dependents = options;
        _selectedDependent = firstAvailable.isNotEmpty
            ? firstAvailable.first
            : (options.isNotEmpty ? options.first : null);
        _parentInfo = alreadyLinked
            ? '$parentName (ja vinculado a este motorista).'
            : 'Responsavel encontrado: $parentName.';
        if (options.isEmpty) {
          _parentInfo =
              '$parentName encontrado, mas sem dependentes cadastrados.';
        }
        if (hasDebt) {
          _inadimplencyWarning = [
            'Atencao: este responsavel possui debitos.',
            if (debtAmount != null) 'Valor: R\$ $debtAmount',
          ].join(' ');
        }
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Falha ao buscar o responsavel.');
    } finally {
      if (mounted) setState(() => _lookingUpCpf = false);
    }
  }

  Future<void> _link() async {
    if (_linkedParentId == null || _selectedDependent == null) return;
    if (_inadimplencyWarning != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirmar vinculo'),
          content: Text(
            '$_inadimplencyWarning\n\nDeseja continuar mesmo assim?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(driverPortalRepositoryProvider).linkClient(
        session.authorizationHeader,
        parentId: _linkedParentId!,
        childId: _selectedDependent!.id,
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

class _DepOption {
  const _DepOption({
    required this.id,
    required this.label,
    required this.blockedByOtherDriver,
  });

  final int id;
  final String label;
  final bool blockedByOtherDriver;
}
