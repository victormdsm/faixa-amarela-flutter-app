import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../providers/parent_portal_providers.dart';

class ParentBoardingsPage extends ConsumerWidget {
  const ParentBoardingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(parentBoardingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Embarques e Desembarques'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => ref.invalidate(parentBoardingsProvider),
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
        ],
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(parentBoardingsProvider),
        ),
        data: (page) {
          if (page.items.isEmpty) {
            return const AppEmptyState(
              message: 'Nenhum registro encontrado.',
              icon: Icons.fact_check_outlined,
              subtitle: 'Embarques e desembarques aparecerão aqui.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg,
            ),
            itemCount: page.items.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) =>
                _BoardingCard(item: page.items[index]),
          );
        },
      ),
    );
  }
}

class _BoardingCard extends StatelessWidget {
  const _BoardingCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final boarding = (item['boarding'] as Map?) ?? const {};
    final route = (boarding['route'] as Map?) ?? const {};
    final client = (item['client'] as Map?) ?? const {};
    final child = (client['child'] as Map?) ?? const {};
    final status = (item['status'] ?? 'N/A').toString();
    final childName = (child['name'] ?? '').toString();
    final routeName = (route['name'] ?? '').toString();
    final hour = (boarding['hour_boarding'] ?? '').toString();
    final theme = Theme.of(context);

    final isDisembarked = status.toLowerCase() == 'disembarked' ||
        status.toLowerCase() == 'desembarcado';
    final isBoarded = status.toLowerCase() == 'boarded' ||
        status.toLowerCase() == 'embarcado';
    final (statusColor, statusBg) = switch (status.toLowerCase()) {
      'boarded' || 'embarcado' => (
          const Color(0xFF0A7E52),
          const Color(0xFF0A7E52).withValues(alpha: 0.10),
        ),
      'disembarked' || 'desembarcado' => (
          AppColors.slate,
          AppColors.surfaceSoft,
        ),
      _ => (AppColors.ink, AppColors.surfaceSoft),
    };
    final statusLabel = isBoarded
        ? 'Embarcado'
        : isDisembarked
            ? 'Desembarcado'
            : status;
    final tileIcon =
        isDisembarked ? Icons.logout_rounded : Icons.login_rounded;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              tileIcon,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        childName.isNotEmpty
                            ? childName
                            : isDisembarked ? 'Desembarque' : 'Embarque',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                        border:
                            Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        statusLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (routeName.isNotEmpty) 'Rota: $routeName',
                    if (hour.isNotEmpty) 'Hora: $hour',
                  ].join(' · '),
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
