import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/app_error_reporter.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../../core/utils/date_formatters.dart';
import '../providers/parent_portal_providers.dart';

class ParentBoardingsPage extends ConsumerWidget {
  const ParentBoardingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(parentBoardingsProvider);

    Future<void> refresh() async {
      ref.invalidate(parentBoardingsProvider);
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      appBar: FaixaAppBar.screen(
        title: 'Embarques e Desembarques',
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => ref.invalidate(parentBoardingsProvider),
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: data.when(
          loading: () => const _ScrollableStatus(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _ScrollableStatus(
            child: FaixaErrorState(
              message: AppErrorReporter.messageFor(error),
              onRetry: () => ref.invalidate(parentBoardingsProvider),
            ),
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return const _ScrollableStatus(
                child: FaixaEmptyState(
                  message: 'Nenhum registro encontrado.',
                  icon: Icons.fact_check_rounded,
                  subtitle: 'Embarques e desembarques aparecerão aqui.',
                ),
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              itemCount: page.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) =>
                  _BoardingCard(item: page.items[index]),
            );
          },
        ),
      ),
    );
  }
}

/// Envolve estados de loading/erro/vazio em uma área rolável para que o
/// pull-to-refresh funcione mesmo sem lista de registros.
class _ScrollableStatus extends StatelessWidget {
  const _ScrollableStatus({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }
}

/// Visual (rótulo, cores, ícone) de um status de embarque — extraído do
/// card para ser testável isoladamente.
///
/// APP-08: o backend emite `absent` quando o motorista marca falta; antes
/// caía no fallback e aparecia o texto cru "absent" para o responsável.
({String label, Color color, Color background, IconData icon})
boardingStatusVisual(String status) {
  return switch (status.toLowerCase()) {
    'boarded' ||
    'embarcado' => (
      label: 'Embarcado',
      color: AppColors.success,
      background: AppColors.successSurface,
      icon: Icons.login_rounded,
    ),
    'disembarked' ||
    'desembarcado' => (
      label: 'Desembarcado',
      color: AppColors.slate,
      background: AppColors.surfaceSoft,
      icon: Icons.logout_rounded,
    ),
    'absent' => (
      label: 'Não embarcou',
      color: AppColors.danger,
      background: AppColors.danger.withValues(alpha: 0.08),
      icon: Icons.cancel_rounded,
    ),
    _ => (
      label: status,
      color: AppColors.ink,
      background: AppColors.surfaceSoft,
      icon: Icons.login_rounded,
    ),
  };
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
    final boardedAt = DateTime.tryParse(
      (boarding['hourBoarding'] ?? '').toString(),
    );
    final theme = Theme.of(context);

    final visual = boardingStatusVisual(status);
    final (statusColor, statusBg) = (visual.color, visual.background);
    final isDisembarked =
        status.toLowerCase() == 'disembarked' ||
        status.toLowerCase() == 'desembarcado';
    final isAbsent = status.toLowerCase() == 'absent';

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(visual.icon, color: statusColor, size: 22),
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
                            : isDisembarked
                            ? 'Desembarque'
                            : isAbsent
                            ? 'Não embarcou'
                            : 'Embarque',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
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
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        visual.label,
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
                    if (boardedAt != null) 'Hora: ${formatDateTime(boardedAt)}',
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
