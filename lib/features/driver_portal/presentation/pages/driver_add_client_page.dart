import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../domain/repositories/enrollments_repository.dart';
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

  ChildLookupResult? _lookupResult;
  String? _inadimplencyWarning;
  String? _error;

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _lookupResult;
    final canLink = result != null && result.found && result.childId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Vincular crianca')),
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
                      'Busque a crianca pelo CPF para solicitar o vinculo ao seu veiculo.',
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
                        labelText: 'CPF da crianca',
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
                      label: const Text('Buscar crianca pelo CPF'),
                    ),

                    // Child info banner
                    if (result != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.found
                                  ? (result.childName ?? 'Crianca encontrada')
                                  : (result.childName ??
                                        'Nenhuma crianca encontrada para este CPF.'),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (result.schoolName != null &&
                                result.schoolName!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Escola: ${result.schoolName}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                            if (result.shiftName != null &&
                                result.shiftName!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Turno: ${result.shiftName}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                            if (result.parentName != null &&
                                result.parentName!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Responsavel: ${result.parentName}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                            if (result.address != null &&
                                result.address!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Endereco: ${result.address}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                            if (result.hasPendingEnrollment) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Ja existe uma solicitacao de vinculo pendente.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.yellowDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
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
    if (_lookupResult != null) {
      setState(() {
        _lookupResult = null;
        _inadimplencyWarning = null;
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

    setState(() {
      _lookingUpCpf = true;
      _error = null;
      _inadimplencyWarning = null;
      _lookupResult = null;
    });

    try {
      final result = await ref
          .read(driverEnrollmentsRepositoryProvider)
          .lookupChildByCpf(cpf);

      setState(() {
        _lookupResult = result;
        if (result.isInDebt) {
          _inadimplencyWarning =
              'Atencao: a crianca possui pendencias financeiras.';
        }
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Falha ao buscar a crianca.');
    } finally {
      if (mounted) setState(() => _lookingUpCpf = false);
    }
  }

  Future<void> _link() async {
    final childId = _lookupResult?.childId;
    if (childId == null) return;
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

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref
          .read(driverEnrollmentsRepositoryProvider)
          .requestEnrollment(childId);
      ref.invalidate(driverEnrollmentsControllerProvider);
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
        _error = 'Falha ao vincular crianca.';
      });
    }
  }
}
