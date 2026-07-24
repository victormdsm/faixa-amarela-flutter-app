import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../driver_portal/presentation/pages/ad_banner_widget.dart';
import '../providers/transport_search_providers.dart';
import '../state/transport_search_controller.dart';
import '../../domain/entities/service_period.dart';
import '../widgets/public_transport_driver_card.dart';
import '../widgets/transport_results_header.dart';
import '../widgets/transport_search_empty_state.dart';
import '../widgets/transport_search_filters.dart';
import '../widgets/transport_search_prompt.dart';

class SearchTransportPage extends ConsumerWidget {
  const SearchTransportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(transportSearchControllerProvider);
    final controller = ref.read(transportSearchControllerProvider.notifier);
    final schools = ref.watch(availableSchoolsProvider);
    final neighborhoods = ref.watch(availableNeighborhoodsProvider);
    final driversAsync = ref.watch(transportDriversProvider);
    final drivers = ref.watch(filteredTransportDriversProvider);

    final hasAnyFilter =
        filters.school != null ||
        filters.neighborhood != null ||
        filters.period != null;

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      appBar: FaixaAppBar.screen(
        title: 'Buscar Transporte',
        actions: [
          if (hasAnyFilter)
            TextButton.icon(
              onPressed: controller.clearAll,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Limpar'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                children: [
                  TransportSearchFilters(
                    filters: filters,
                    schools: schools,
                    neighborhoods: neighborhoods,
                    driversAsync: driversAsync,
                    filteredCount: drivers.length,
                    onSchoolSelected: controller.setSchool,
                    onNeighborhoodSelected: controller.setNeighborhood,
                    onPeriodChanged: controller.setPeriod,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const AdBannerWidget(height: 104),
                ],
              ),
            ),
          ),
          if (!filters.canSearch)
            const SliverToBoxAdapter(child: TransportSearchPrompt())
          else if (drivers.isEmpty)
            SliverToBoxAdapter(
              child: TransportSearchEmptyState(
                schoolName: filters.school,
                neighborhoodName: filters.neighborhood,
                periodLabel: filters.period?.shortLabel,
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: TransportResultsHeader(count: drivers.length),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                0,
              ),
              sliver: SliverList.separated(
                itemCount: drivers.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) =>
                    PublicTransportDriverCard(driver: drivers[i]),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }
}
