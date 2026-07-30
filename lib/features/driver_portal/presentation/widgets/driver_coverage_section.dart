import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/catalog_option.dart';
import '../../../../core/presentation/widgets/faixa_searchable_select.dart';
import '../../../../core/presentation/widgets/faixa_section_card.dart';
import '../../../../domain/models/driver_profile_change_request.dart';
import 'driver_change_requests_card.dart';

/// Seção de cobertura (escolas, bairros e turnos) nas configurações do motorista.
class DriverCoverageSection extends StatelessWidget {
  const DriverCoverageSection({
    super.key,
    required this.schoolsAsync,
    required this.districtsAsync,
    required this.shiftOptions,
    required this.selectedSchoolIds,
    required this.districtShiftMap,
    required this.requestsAsync,
    this.pendingRequest,
    required this.isSaving,
    required this.onSchoolsChanged,
    required this.onDistrictsChanged,
    required this.onToggleShift,
  });

  final AsyncValue<List<CatalogOption>> schoolsAsync;
  final AsyncValue<List<CatalogOption>> districtsAsync;
  final List<CatalogOption> shiftOptions;
  final Set<int> selectedSchoolIds;
  final Map<int, Set<int>> districtShiftMap;
  final AsyncValue<List<DriverProfileChangeRequest>> requestsAsync;
  final DriverProfileChangeRequest? pendingRequest;
  final bool isSaving;
  final ValueChanged<Set<int>> onSchoolsChanged;
  final ValueChanged<Set<int>> onDistrictsChanged;
  final void Function(int districtId, int shiftId) onToggleShift;

  @override
  Widget build(BuildContext context) {
    return FaixaSectionCard(
      icon: Icons.map_rounded,
      title: 'Cobertura',
      subtitle: 'Escolas, bairros e períodos atendidos.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CoverageStatusBanner(
            pendingRequest: pendingRequest,
            schoolsCount: selectedSchoolIds.length,
            districtsCount: districtShiftMap.length,
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
            enabled: !isSaving && schoolsAsync.hasValue,
            onConfirm: onSchoolsChanged,
          ),
          if (schoolsAsync.hasValue && selectedSchoolIds.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm + 2),
            _CoverageChips(
              options: schoolsAsync.value!,
              selectedIds: selectedSchoolIds,
            ),
          ],
          const SizedBox(height: 12),
          FaixaSearchableSelect<CatalogOption>(
            label: 'Bairros atendidos',
            count: districtShiftMap.length,
            icon: Icons.location_city_rounded,
            items: districtsAsync.value ?? const [],
            selectedIds: districtShiftMap.keys.toSet(),
            itemToId: (item) => item.id,
            itemToName: (item) => item.name,
            title: 'Bairros atendidos',
            searchHint: 'Buscar bairro',
            enabled: !isSaving && districtsAsync.hasValue,
            onConfirm: (value) {
              final keep = value.toSet();
              onDistrictsChanged(keep);
            },
          ),
          if (districtsAsync.hasValue && districtShiftMap.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DistrictShiftEditor(
              districtOptions: districtsAsync.value!,
              shiftOptions: shiftOptions,
              districtShiftMap: districtShiftMap,
              enabled: !isSaving,
              onToggleShift: onToggleShift,
            ),
          ],
        ],
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
      final districtsReq =
          pendingRequest!.requestedDistrictShiftMap?.length ?? 0;
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

class _DistrictShiftEditor extends StatelessWidget {
  const _DistrictShiftEditor({
    required this.districtOptions,
    required this.shiftOptions,
    required this.districtShiftMap,
    required this.enabled,
    required this.onToggleShift,
  });

  final List<CatalogOption> districtOptions;
  final List<CatalogOption> shiftOptions;
  final Map<int, Set<int>> districtShiftMap;
  final bool enabled;
  final void Function(int districtId, int shiftId) onToggleShift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (districtShiftMap.isEmpty) return const SizedBox.shrink();

    final districtById = {for (final d in districtOptions) d.id: d};
    final sortedEntries = districtShiftMap.entries.toList()
      ..sort((a, b) {
        final aName = districtById[a.key]?.name ?? a.key.toString();
        final bName = districtById[b.key]?.name ?? b.key.toString();
        return aName.compareTo(bName);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Períodos por bairro',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.slate,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        ...sortedEntries.map((entry) {
          final district = districtById[entry.key];
          final selectedShiftIds = entry.value;
          final allSelected =
              shiftOptions.isNotEmpty &&
              shiftOptions.every((s) => selectedShiftIds.contains(s.id));

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  child: Row(
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
                          Icons.location_on_rounded,
                          size: 15,
                          color: selectedShiftIds.isNotEmpty
                              ? AppColors.success
                              : AppColors.muted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          district?.name ?? 'Bairro #${entry.key}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (selectedShiftIds.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm - 1,
                            vertical: AppSpacing.xs - 2,
                          ),
                          decoration: BoxDecoration(
                            color: allSelected
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.yellowLight,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            allSelected
                                ? 'Todos os turnos'
                                : '${selectedShiftIds.length}/${shiftOptions.length} turnos',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: allSelected
                                  ? AppColors.success
                                  : AppColors.yellowDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: shiftOptions
                        .map((shift) {
                          final isSelected = selectedShiftIds.contains(
                            shift.id,
                          );
                          return GestureDetector(
                            onTap: enabled
                                ? () => onToggleShift(entry.key, shift.id)
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm - 1,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.yellow
                                    : AppColors.surfaceSoft,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.yellowDark
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 13,
                                      color: AppColors.ink,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                  ],
                                  Text(
                                    shift.name,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: isSelected
                                              ? AppColors.ink
                                              : AppColors.slate,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
