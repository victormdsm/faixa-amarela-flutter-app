import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/catalog_option.dart';
import '../../../../core/presentation/widgets/faixa_searchable_select.dart';
import '../../../../core/presentation/widgets/faixa_section_card.dart';
import '../../../../domain/models/driver_profile_change_request.dart';
import 'driver_change_requests_card.dart';

/// Seção de cobertura (escolas, bairros e turnos) nas configurações do motorista.
///
/// O motorista escolhe escolas e bairros. Para cada escola selecionada,
/// escolhe também quais turnos atende (schools_has_shifts).
class DriverCoverageSection extends StatelessWidget {
  const DriverCoverageSection({
    super.key,
    required this.schoolsAsync,
    required this.districtsAsync,
    required this.shiftOptions,
    required this.selectedSchoolIds,
    required this.schoolShiftMap,
    required this.selectedDistrictIds,
    required this.districtShiftMap,
    required this.requestsAsync,
    this.pendingRequest,
    required this.isSaving,
    required this.editMode,
    this.onToggleEdit,
    required this.onSchoolsChanged,
    required this.onDistrictsChanged,
    required this.onSchoolShiftMapChanged,
    required this.onDistrictShiftMapChanged,
  });

  final AsyncValue<List<CatalogOption>> schoolsAsync;
  final AsyncValue<List<CatalogOption>> districtsAsync;
  final List<CatalogOption> shiftOptions;
  final Set<int> selectedSchoolIds;

  /// Turnos por escola selecionados pelo motorista.
  final Map<int, Set<int>> schoolShiftMap;
  final Set<int> selectedDistrictIds;

  /// Turnos por bairro selecionados pelo motorista.
  final Map<int, Set<int>> districtShiftMap;
  final AsyncValue<List<DriverProfileChangeRequest>> requestsAsync;
  final DriverProfileChangeRequest? pendingRequest;
  final bool isSaving;
  final bool editMode;
  final VoidCallback? onToggleEdit;
  final ValueChanged<Set<int>> onSchoolsChanged;
  final ValueChanged<Set<int>> onDistrictsChanged;
  final ValueChanged<Map<int, Set<int>>> onSchoolShiftMapChanged;
  final ValueChanged<Map<int, Set<int>>> onDistrictShiftMapChanged;

  @override
  Widget build(BuildContext context) {
    return FaixaSectionCard(
      icon: Icons.map_rounded,
      title: 'Cobertura',
      subtitle: 'Escolas, bairros e turnos atendidos.',
      trailing: _buildEditToggle(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CoverageStatusBanner(
            pendingRequest: pendingRequest,
            schoolsCount: selectedSchoolIds.length,
            districtsCount: selectedDistrictIds.length,
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          requestsAsync.when(
            data: (items) {
              if (items.isEmpty) return const SizedBox.shrink();
              return DriverChangeRequestsCard(items: items);
            },
            loading: () => const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          FaixaSearchableSelect<CatalogOption>(
            label: 'Escolas atendidas',
            count: selectedSchoolIds.length,
            icon: Icons.school_rounded,
            items: schoolsAsync.value ?? const [],
            selectedIds: selectedSchoolIds,
            itemToId: (item) => item.id,
            itemToName: (item) => item.name,
            title: 'Escolas atendidas',
            searchHint: 'Buscar escola',
            enabled: editMode && !isSaving && schoolsAsync.hasValue,
            onConfirm: onSchoolsChanged,
          ),
          if (schoolsAsync.hasValue && selectedSchoolIds.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm + 2),
            _CoverageChips(
              options: schoolsAsync.value!,
              selectedIds: selectedSchoolIds,
            ),
            const SizedBox(height: 12),
            _SchoolShiftSummary(
              schoolOptions: schoolsAsync.value!,
              shiftOptions: shiftOptions,
              selectedSchoolIds: selectedSchoolIds,
              schoolShiftMap: schoolShiftMap,
              enabled: editMode && !isSaving,
              onShiftToggle: onSchoolShiftMapChanged,
            ),
          ],
          const SizedBox(height: 12),
          FaixaSearchableSelect<CatalogOption>(
            label: 'Bairros atendidos',
            count: selectedDistrictIds.length,
            icon: Icons.location_city_rounded,
            items: districtsAsync.value ?? const [],
            selectedIds: selectedDistrictIds,
            itemToId: (item) => item.id,
            itemToName: (item) => item.name,
            title: 'Bairros atendidos',
            searchHint: 'Buscar bairro',
            enabled: editMode && !isSaving && districtsAsync.hasValue,
            onConfirm: (value) {
              final keep = value.toSet();
              onDistrictsChanged(keep);
            },
          ),
          if (districtsAsync.hasValue && selectedDistrictIds.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm + 2),
            _CoverageChips(
              options: districtsAsync.value!,
              selectedIds: selectedDistrictIds,
            ),
            const SizedBox(height: 12),
            _DistrictShiftEditor(
              districtOptions: districtsAsync.value!,
              shiftOptions: shiftOptions,
              selectedDistrictIds: selectedDistrictIds,
              districtShiftMap: districtShiftMap,
              enabled: editMode && !isSaving,
              onChanged: onDistrictShiftMapChanged,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditToggle(BuildContext context) {
    // Rótulos curtos (mesmo motivo das demais seções): texto longo esmagava
    // o título em telas estreitas; a ação completa fica no tooltip.
    if (!editMode) {
      return Tooltip(
        message: 'Editar cobertura',
        child: TextButton.icon(
          onPressed: isSaving ? null : onToggleEdit,
          icon: const Icon(Icons.edit_rounded, size: 16),
          label: const Text('Editar'),
        ),
      );
    }
    return Tooltip(
      message: 'Cancelar edição',
      child: TextButton.icon(
        onPressed: isSaving ? null : onToggleEdit,
        icon: const Icon(Icons.lock_outline_rounded, size: 16),
        label: const Text('Cancelar'),
        style: TextButton.styleFrom(foregroundColor: AppColors.slate),
      ),
    );
  }
}

class _CoverageStatusBanner extends StatelessWidget {
  const _CoverageStatusBanner({
    required this.pendingRequest,
    required this.schoolsCount,
    required this.districtsCount,
  });

  final DriverProfileChangeRequest? pendingRequest;
  final int schoolsCount;
  final int districtsCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (pendingRequest != null) {
      final status = pendingRequest!.status.toLowerCase().trim();
      final schoolsReq = pendingRequest!.requestedSchoolIds?.length ?? 0;
      // Contrato novo: requestedDistrictIds (lista). Solicitações antigas
      // carregam os bairros como chaves do requestedDistrictShiftMap.
      final districtsReq = pendingRequest!.requestedDistrictIds?.length ??
          pendingRequest!.requestedDistrictShiftMap?.length ??
          0;
      final reviewNote = (pendingRequest!.reviewNote ?? '').trim();
      final photoLabels = <String>[
        if ((pendingRequest!.requestedAvatarPath ?? '').isNotEmpty)
          'foto do motorista',
        if ((pendingRequest!.requestedVehicleImagePath ?? '').isNotEmpty)
          'foto do veículo',
      ];
      final coverageLabel = '$schoolsReq escola(s) e $districtsReq bairro(s)';
      final pendingLabel = photoLabels.isEmpty
          ? coverageLabel
          : '$coverageLabel, ${photoLabels.join(' e ')}';
      if (status == 'pending') {
        return _CoverageBannerContent(
          theme: theme,
          color: AppColors.yellowDark,
          icon: Icons.hourglass_top_rounded,
          title: 'Aguardando aprovação',
          subtitle: '$pendingLabel aguardando revisão do administrador.',
          showPulse: true,
        );
      }
      if (status == 'rejected') {
        return _CoverageBannerContent(
          theme: theme,
          color: AppColors.danger,
          icon: Icons.cancel_rounded,
          title: 'Solicitação reprovada',
          subtitle: reviewNote.isNotEmpty
              ? 'Motivo do admin: $reviewNote'
              : 'Sua última solicitação foi reprovada pelo admin.',
        );
      }
      if (status == 'approved') {
        return _CoverageBannerContent(
          theme: theme,
          color: AppColors.success,
          icon: Icons.verified_rounded,
          title: 'Última solicitação aprovada',
          subtitle: 'As alterações revisadas foram aprovadas pelo admin.',
        );
      }
    }

    if (schoolsCount > 0 || districtsCount > 0) {
      return _CoverageBannerContent(
        theme: theme,
        color: AppColors.success,
        icon: Icons.check_circle_rounded,
        title: 'Atendimento ativo',
        subtitle:
            '$schoolsCount escola(s) e $districtsCount bairro(s) visíveis nas buscas de responsáveis.',
      );
    }

    return _CoverageBannerContent(
      theme: theme,
      color: AppColors.muted,
      icon: Icons.info_outline_rounded,
      title: 'Não configurado',
      subtitle:
          'Adicione escolas e bairros para aparecer nas buscas de responsáveis.',
    );
  }
}

class _CoverageBannerContent extends StatelessWidget {
  const _CoverageBannerContent({
    required this.theme,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showPulse = false,
  });

  final ThemeData theme;
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showPulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                    if (showPulse) ...[
                      const SizedBox(width: 8),
                      _PulseDot(color: color),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.25,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _CoverageChips extends StatelessWidget {
  const _CoverageChips({required this.options, required this.selectedIds});

  final List<CatalogOption> options;
  final Set<int> selectedIds;

  @override
  Widget build(BuildContext context) {
    final selected = options.where((e) => selectedIds.contains(e.id)).toList();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: selected
          .map(
            (option) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.yellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: AppColors.yellow.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: AppColors.yellowDark,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    option.name,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}


/// Seletor de turnos por escola. Para cada escola selecionada, o motorista
/// escolhe quais turnos atende (schools_has_shifts).
class _SchoolShiftSummary extends StatelessWidget {
  const _SchoolShiftSummary({
    required this.schoolOptions,
    required this.shiftOptions,
    required this.selectedSchoolIds,
    required this.schoolShiftMap,
    required this.enabled,
    required this.onShiftToggle,
  });

  final List<CatalogOption> schoolOptions;
  final List<CatalogOption> shiftOptions;
  final Set<int> selectedSchoolIds;
  final Map<int, Set<int>> schoolShiftMap;
  final bool enabled;
  final ValueChanged<Map<int, Set<int>>> onShiftToggle;

  void _toggleShift(int schoolId, int shiftId) {
    final next = <int, Set<int>>{
      for (final entry in schoolShiftMap.entries) entry.key: Set<int>.from(entry.value),
    };
    final selected = next.putIfAbsent(schoolId, () => <int>{});
    if (!selected.add(shiftId)) {
      selected.remove(shiftId);
    }
    if (selected.isEmpty) {
      next.remove(schoolId);
    }
    onShiftToggle(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (selectedSchoolIds.isEmpty) return const SizedBox.shrink();

    final schoolById = {for (final s in schoolOptions) s.id: s};
    final sortedIds = selectedSchoolIds.toList(growable: false)
      ..sort((a, b) {
        final aName = schoolById[a]?.name ?? a.toString();
        final bName = schoolById[b]?.name ?? b.toString();
        return aName.compareTo(bName);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 15,
              color: AppColors.muted,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Turnos atendidos por escola',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...sortedIds.map((schoolId) {
          final school = schoolById[schoolId];
          final schoolShifts = school?.shifts ?? const <CatalogOption>[];
          final selectedShiftIds = schoolShiftMap[schoolId] ?? const <int>{};

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selectedShiftIds.isNotEmpty
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
              color: AppColors.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: selectedShiftIds.isNotEmpty
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        size: 15,
                        color: selectedShiftIds.isNotEmpty
                            ? AppColors.success
                            : AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        school?.name ?? 'Escola #$schoolId',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (schoolShifts.isEmpty)
                  Text(
                    'Nenhum turno cadastrado para esta escola.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: schoolShifts.map((shift) {
                      final selected = selectedShiftIds.contains(shift.id);
                      return InkWell(
                        onTap: enabled
                            ? () => _toggleShift(schoolId, shift.id)
                            : null,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm - 1,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.yellow.withValues(alpha: 0.15)
                                : AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(
                              AppRadius.full,
                            ),
                            border: Border.all(
                              color: selected
                                  ? AppColors.yellow.withValues(alpha: 0.5)
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            shift.name,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: selected ? AppColors.ink : AppColors.slate,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(growable: false),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Seletor de turnos por bairro. Para cada bairro selecionado, o motorista
/// escolhe quais turnos atende (contrato `coverage.districtShiftMap`).
class _DistrictShiftEditor extends StatelessWidget {
  const _DistrictShiftEditor({
    required this.districtOptions,
    required this.shiftOptions,
    required this.selectedDistrictIds,
    required this.districtShiftMap,
    required this.enabled,
    required this.onChanged,
  });

  final List<CatalogOption> districtOptions;
  final List<CatalogOption> shiftOptions;
  final Set<int> selectedDistrictIds;
  final Map<int, Set<int>> districtShiftMap;
  final bool enabled;
  final ValueChanged<Map<int, Set<int>>> onChanged;

  void _toggleShift(int districtId, int shiftId) {
    final next = <int, Set<int>>{
      for (final entry in districtShiftMap.entries)
        entry.key: Set<int>.from(entry.value),
    };
    final selected = next.putIfAbsent(districtId, () => <int>{});
    if (!selected.add(shiftId)) {
      selected.remove(shiftId);
    }
    if (selected.isEmpty) {
      next.remove(districtId);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (selectedDistrictIds.isEmpty) return const SizedBox.shrink();

    final districtById = {for (final d in districtOptions) d.id: d};
    final sortedIds = selectedDistrictIds.toList(growable: false)
      ..sort((a, b) {
        final aName = districtById[a]?.name ?? a.toString();
        final bName = districtById[b]?.name ?? b.toString();
        return aName.compareTo(bName);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 15,
              color: AppColors.muted,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Turnos atendidos por bairro',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...sortedIds.map((districtId) {
          final district = districtById[districtId];
          final selectedShiftIds = districtShiftMap[districtId] ?? const <int>{};

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selectedShiftIds.isNotEmpty
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
              color: AppColors.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: selectedShiftIds.isNotEmpty
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        Icons.location_city_rounded,
                        size: 15,
                        color: selectedShiftIds.isNotEmpty
                            ? AppColors.success
                            : AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        district?.name ?? 'Bairro #$districtId',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: shiftOptions.map((shift) {
                    final selected = selectedShiftIds.contains(shift.id);
                    return InkWell(
                      onTap: enabled
                          ? () => _toggleShift(districtId, shift.id)
                          : null,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm - 1,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.yellow.withValues(alpha: 0.15)
                              : AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(
                            AppRadius.full,
                          ),
                          border: Border.all(
                            color: selected
                                ? AppColors.yellow.withValues(alpha: 0.5)
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          shift.name,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: selected ? AppColors.ink : AppColors.slate,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(growable: false),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
