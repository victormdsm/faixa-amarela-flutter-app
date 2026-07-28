import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../../core/presentation/widgets/faixa_section_card.dart';
import '../../../../core/utils/validators.dart';
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
      backgroundColor: AppColors.surfaceSoft,
      appBar: FaixaAppBar.screen(title: 'Vincular crianca'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            FaixaSectionCard(
              title: 'Vinculo por CPF ou codigo',
              subtitle:
                  'Busque a crianca pelo CPF ou pelo codigo compartilhado pelo responsavel para solicitar o vinculo ao seu veiculo.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _cpfController,
                    keyboardType: TextInputType.text,
                    enabled: !_submitting,
                    onChanged: (_) => _resetLookup(),
                    decoration: const InputDecoration(
                      labelText: 'CPF ou codigo da crianca',
                      hintText: '000.000.000-00 ou codigo (UUID)',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

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
                    label: const Text('Buscar crianca'),
                  ),

                  // Child info banner
                  if (result != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
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
                            const SizedBox(height: AppSpacing.xs),
                            AppIconTextRow(
                              icon: Icons.school_outlined,
                              text: 'Escola: ${result.schoolName}',
                            ),
                          ],
                          if (result.shiftName != null &&
                              result.shiftName!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            AppIconTextRow(
                              icon: Icons.access_time_rounded,
                              text: 'Turno: ${result.shiftName}',
                            ),
                          ],
                          if (result.districtName != null &&
                              result.districtName!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            AppIconTextRow(
                              icon: Icons.location_city_rounded,
                              text: 'Bairro: ${result.districtName}',
                            ),
                          ],
                          if (result.parentName != null &&
                              result.parentName!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            AppIconTextRow(
                              icon: Icons.person_outline_rounded,
                              text: 'Responsavel: ${result.parentName}',
                            ),
                          ],
                          if (result.address != null &&
                              result.address!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            AppIconTextRow(
                              icon: Icons.location_on_outlined,
                              text: 'Endereco: ${result.address}',
                            ),
                          ],
                          if (result.hasPendingEnrollment) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Ja existe uma solicitacao de vinculo pendente.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.yellowDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (result.hasActiveEnrollmentWithOtherDriver) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Vinculo ativo com: ${result.activeDriverNames.isNotEmpty ? result.activeDriverNames.join(', ') : 'outro motorista'}.',
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
                    const SizedBox(height: AppSpacing.md),
                    AppInfoBanner(
                      message: _inadimplencyWarning!,
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.yellowDark,
                    ),
                  ],

                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    FaixaErrorBanner(message: _error!),
                  ],

                  const SizedBox(height: AppSpacing.lg),

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
    final query = _cpfController.text.trim();
    final isUuid = Validators.isUuid(query);
    final digits = query.replaceAll(RegExp(r'\D'), '');
    if (!isUuid && digits.length != 11) {
      setState(() => _error = 'Informe um CPF valido ou o codigo da crianca.');
      return;
    }
    final lookup = isUuid ? query.toLowerCase() : digits;

    setState(() {
      _lookingUpCpf = true;
      _error = null;
      _inadimplencyWarning = null;
      _lookupResult = null;
    });

    try {
      final result = await ref
          .read(driverEnrollmentsRepositoryProvider)
          .lookupChildByCpf(lookup);

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
    final result = _lookupResult;
    final childId = result?.childId;
    if (childId == null) return;

    // F4 multi-vínculo: exige confirmação explícita antes de solicitar o
    // vínculo quando a criança já tem matrícula ativa com outro motorista.
    if (result!.hasActiveEnrollmentWithOtherDriver) {
      final names = result.activeDriverNames.isNotEmpty
          ? result.activeDriverNames.join(', ')
          : 'outro motorista';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Vinculo ativo existente'),
          content: Text(
            'Esta crianca ja possui vinculo ativo com $names. '
            'Deseja continuar e solicitar mesmo assim?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Solicitar mesmo assim'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

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
