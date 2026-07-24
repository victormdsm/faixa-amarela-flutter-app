import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/searchable_select_field.dart';
import '../../domain/entities/public_transport_driver.dart';
import '../../domain/entities/service_period.dart';
import '../state/transport_search_filters_state.dart';
import 'transport_filter_summary.dart';

/// Card com os filtros de busca por transporte escolar.
class TransportSearchFilters extends StatelessWidget {
  const TransportSearchFilters({
    super.key,
    required this.filters,
    required this.schools,
    required this.neighborhoods,
    required this.driversAsync,
    required this.filteredCount,
    required this.onSchoolSelected,
    required this.onNeighborhoodSelected,
    required this.onPeriodChanged,
  });

  final TransportSearchFiltersState filters;
  final List<String> schools;
  final List<String> neighborhoods;
  final AsyncValue<List<PublicTransportDriver>> driversAsync;
  final int filteredCount;
  final ValueChanged<String?> onSchoolSelected;
  final ValueChanged<String?> onNeighborhoodSelected;
  final ValueChanged<ServicePeriod?> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSubtle,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.ink,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Text(
                'Filtrar motoristas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md + 2),
          SearchableSelectField(
            label: 'Escola',
            hintText: 'Selecione a escola',
            value: filters.school,
            options: schools,
            onSelected: onSchoolSelected,
            onCleared: filters.school == null
                ? null
                : () => onSchoolSelected(null),
            emptyResultsText: 'Nenhuma escola carregada da API.',
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          SearchableSelectField(
            label: 'Bairro',
            hintText: 'Selecione o bairro',
            value: filters.neighborhood,
            options: neighborhoods,
            onSelected: onNeighborhoodSelected,
            onCleared: filters.neighborhood == null
                ? null
                : () => onNeighborhoodSelected(null),
            emptyResultsText: 'Nenhum bairro carregado da API.',
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          SegmentedButton<ServicePeriod>(
            multiSelectionEnabled: false,
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            segments: ServicePeriod.values
                .map(
                  (period) => ButtonSegment<ServicePeriod>(
                    value: period,
                    label: Text(period.shortLabel),
                  ),
                )
                .toList(growable: false),
            selected: filters.period == null
                ? const <ServicePeriod>{}
                : <ServicePeriod>{filters.period!},
            onSelectionChanged: (selection) {
              onPeriodChanged(selection.isEmpty ? null : selection.first);
            },
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          driversAsync.when(
            loading: () => const AppStatusRow(
              icon: Icons.sync,
              color: AppColors.yellowDark,
              message: 'Aguardando filtros para consultar a API.',
            ),
            error: (error, _) => AppStatusRow(
              icon: Icons.error_outline_rounded,
              color: AppColors.danger,
              message: 'Erro na busca: $error',
            ),
            data: (_) => TransportFilterSummary(
              hasRequiredFields: filters.canSearch,
              resultsCount: filteredCount,
            ),
          ),
        ],
      ),
    );
  }
}
