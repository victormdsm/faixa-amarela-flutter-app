import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/searchable_select_field.dart';
import '../../../../core/utils/whatsapp_launcher.dart';
import '../../domain/entities/public_transport_driver.dart';
import '../../domain/entities/service_period.dart';
import '../providers/transport_search_providers.dart';
import '../state/transport_search_controller.dart';
import '../state/transport_search_filters_state.dart';

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

    final hasAnyFilter = filters.school != null ||
        filters.neighborhood != null ||
        filters.period != null;

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      appBar: AppBar(
        title: const Text('Buscar Transporte'),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _FilterCard(
                filters: filters,
                schools: schools,
                neighborhoods: neighborhoods,
                driversAsync: driversAsync,
                filteredCount: drivers.length,
                onSchoolSelected: controller.setSchool,
                onNeighborhoodSelected: controller.setNeighborhood,
                onPeriodChanged: controller.setPeriod,
              ),
            ),
          ),
          if (!filters.canSearch)
            const SliverToBoxAdapter(child: _SearchPrompt())
          else if (drivers.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyState(
                schoolName: filters.school,
                neighborhoodName: filters.neighborhood,
                periodLabel: filters.period?.shortLabel,
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: _ResultsHeader(count: drivers.length),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverList.separated(
                itemCount: drivers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _DriverCard(driver: drivers[i]),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tune_rounded, color: AppColors.ink, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Filtrar motoristas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SearchableSelectField(
            label: 'Escola',
            hintText: 'Selecione a escola',
            value: filters.school,
            options: schools,
            onSelected: onSchoolSelected,
            onCleared: filters.school == null ? null : () => onSchoolSelected(null),
            emptyResultsText: 'Nenhuma escola carregada da API.',
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 10),
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
          const SizedBox(height: 10),
          driversAsync.when(
            loading: () => const _StatusRow(
              icon: Icons.sync,
              color: AppColors.yellowDark,
              message: 'Aguardando filtros para consultar a API.',
            ),
            error: (error, _) => _StatusRow(
              icon: Icons.error_outline_rounded,
              color: AppColors.danger,
              message: 'Erro na busca: $error',
            ),
            data: (_) => _FilterSummary(
              hasRequiredFields: filters.canSearch,
              resultsCount: filteredCount,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.manage_search_rounded,
              size: 36,
              color: AppColors.yellowDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Preencha os filtros',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Selecione escola, bairro e periodo para ver os motoristas disponiveis.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.slate),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.schoolName, this.neighborhoodName, this.periodLabel});

  final String? schoolName;
  final String? neighborhoodName;
  final String? periodLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 36,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum motorista encontrado',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Nao ha motoristas cadastrados para essa combinacao de escola, bairro e periodo.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.slate),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              final message = [
                'Ola, sou usuario(a) do app Faixa Amarela e nao encontrei transporte disponivel.',
                'Gostaria de confirmar com o sindicato (SINPROVETE).',
                '',
                'Minha busca:',
                if ((schoolName ?? '').trim().isNotEmpty)
                  'Escola: ${schoolName!.trim()}',
                if ((neighborhoodName ?? '').trim().isNotEmpty)
                  'Bairro: ${neighborhoodName!.trim()}',
                if ((periodLabel ?? '').trim().isNotEmpty)
                  'Periodo: ${periodLabel!.trim()}',
              ].join('\n');
              final result = await WhatsAppLauncher.openChat(
                phone: '+55 45 99128-6668',
                contactName: 'SINPROVETE',
                message: message,
              );
              if (!context.mounted || result.success) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result.errorMessage ?? 'Falha ao abrir contato da SINPROVETE.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.support_agent_rounded),
            label: const Text('Contatar SINPROVETE'),
          ),
        ],
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'motorista${count == 1 ? '' : 's'} encontrado${count == 1 ? '' : 's'}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSummary extends StatelessWidget {
  const _FilterSummary({
    required this.hasRequiredFields,
    required this.resultsCount,
  });

  final bool hasRequiredFields;
  final int resultsCount;

  @override
  Widget build(BuildContext context) {
    final color = !hasRequiredFields
        ? AppColors.yellowDark
        : resultsCount > 0
        ? AppColors.success
        : AppColors.danger;
    final icon = !hasRequiredFields
        ? Icons.tune_rounded
        : resultsCount > 0
        ? Icons.check_circle_outline_rounded
        : Icons.warning_amber_rounded;
    final message = !hasRequiredFields
        ? 'Preencha todos os filtros para habilitar a busca.'
        : resultsCount > 0
        ? '$resultsCount opcao(oes) encontradas na API.'
        : 'Nenhum motorista encontrado para esta combinacao.';

    return _StatusRow(icon: icon, color: color, message: message);
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver});

  final PublicTransportDriver driver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasVehicleImage = (driver.vehicleImageUrl ?? '').trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasVehicleImage)
            Stack(
              children: [
                SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: Image.network(
                    driver.vehicleImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const _VehicleBannerFallback(),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.ink.withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            const _VehicleBannerFallback(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _DriverAvatar(driver: driver, radius: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if ((driver.cellPhone ?? '').isNotEmpty)
                            Text(
                              driver.cellPhone!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.slate,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (driver.schools.isNotEmpty || driver.districts.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  if (driver.schools.isNotEmpty)
                    _InfoRow(
                      icon: Icons.school_outlined,
                      text: driver.schools.join(' · '),
                    ),
                  if (driver.districts.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _InfoRow(
                      icon: Icons.location_city_outlined,
                      text: driver.districts.join(' · '),
                    ),
                  ],
                ],
                if (driver.information != null &&
                    driver.information!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.info_outline_rounded,
                    text: driver.information!,
                    italic: true,
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final result = await WhatsAppLauncher.openChat(
                        phone: driver.cellPhone,
                        contactName: driver.name,
                      );
                      if (!context.mounted || result.success) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result.errorMessage ?? 'Falha ao abrir o WhatsApp.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.forum_rounded),
                    label: const Text('Falar no WhatsApp'),
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

class _VehicleBannerFallback extends StatelessWidget {
  const _VehicleBannerFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      color: AppColors.yellow.withValues(alpha: 0.15),
      child: const Center(
        child: Icon(
          Icons.directions_bus_rounded,
          size: 42,
          color: AppColors.yellowDark,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.italic = false,
  });

  final IconData icon;
  final String text;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: AppColors.slate),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.slate,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({required this.driver, this.radius = 20});

  final PublicTransportDriver driver;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasImage = (driver.avatarUrl ?? '').trim().isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.yellowLight,
      backgroundImage: hasImage ? NetworkImage(driver.avatarUrl!) : null,
      onBackgroundImageError: hasImage ? (error, stackTrace) {} : null,
      child: hasImage
          ? null
          : Text(
              driver.name.isNotEmpty
                  ? driver.name.characters.first.toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
