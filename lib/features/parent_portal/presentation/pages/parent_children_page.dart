import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/app_error_reporter.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/e2e_keys.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../../domain/models/child.dart';
import '../../../../features/catalog/data/catalog_repository.dart';
import '../../../../ui/core/widgets/child_summary_card.dart';
import '../../../../ui/core/widgets/skeleton_list.dart';
import '../providers/parent_portal_providers.dart';

class ParentChildrenPage extends ConsumerWidget {
  const ParentChildrenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(childrenControllerProvider);
    final schoolsAsync = ref.watch(schoolsCatalogProvider);

    final schoolsMap = schoolsAsync.when(
      loading: () => const <int, String>{},
      error: (_, _) => const <int, String>{},
      data: (schools) => {for (final s in schools) s.id: s.name},
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.surfaceSoft,
        appBar: FaixaAppBar.screen(
          title: 'Meus Dependentes',
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              onPressed: () =>
                  ref.read(childrenControllerProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 20),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          key: E2EKeys.childCreateButton,
          onPressed: () => context.push(AppRoutes.parentChildrenAdd),
          child: const Icon(Icons.add_rounded),
        ),
        body: state.when(
          loading: () => const SkeletonList(),
          error: (error, _) => FaixaErrorState(
            message: AppErrorReporter.messageFor(error),
            onRetry: () =>
                ref.read(childrenControllerProvider.notifier).refresh(),
          ),
          data: (children) {
            if (children.isEmpty) {
              return FaixaEmptyState(
                message: 'Nenhum dependente encontrado.',
                icon: Icons.child_care_rounded,
                subtitle: 'Adicione um dependente para começar.',
                actionLabel: 'Adicionar dependente',
                onAction: () => context.push(AppRoutes.parentChildrenAdd),
              );
            }
            return ListView.builder(
              // Folga inferior para o FAB (56 + margens) respeitando a
              // gesture bar do aparelho (antes era 100 fixo).
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                88 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              itemCount: children.length,
              itemBuilder: (context, index) {
                final child = children[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ChildSummaryCard(
                    child: child,
                    schoolName: schoolsMap[child.schoolId],
                    hasRoute: null,
                    onTap: () => _openChildDetail(context, child),
                    onEdit: () => _editChild(context, child),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _editChild(BuildContext context, Child child) {
    context.push(AppRoutes.parentChildrenAdd, extra: child);
  }

  void _openChildDetail(BuildContext context, Child child) {
    context.push(AppRoutes.parentChildDetail, extra: child);
  }
}
