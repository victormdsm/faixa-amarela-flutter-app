import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../domain/models/child.dart';
import '../../../../ui/core/widgets/child_summary_card.dart';
import '../../../../ui/core/widgets/skeleton_list.dart';
import '../providers/parent_portal_providers.dart';

class ParentChildrenPage extends ConsumerWidget {
  const ParentChildrenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(childrenControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dependentes'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () =>
                ref.read(childrenControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.parentChildrenAdd),
        icon: const Icon(Icons.child_care_outlined, size: 20),
        label: const Text('Adicionar'),
      ),
      body: state.when(
        loading: () => const SkeletonList(),
        error: (error, _) => AppErrorState(
          message: error is Exception
              ? error.toString()
              : 'Erro ao carregar dependentes.',
          onRetry: () =>
              ref.read(childrenControllerProvider.notifier).refresh(),
        ),
        data: (children) {
          if (children.isEmpty) {
            return const AppEmptyState(
              message: 'Nenhum dependente encontrado.',
              icon: Icons.child_care_outlined,
              subtitle: 'Adicione um dependente para comecar.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              100,
            ),
            itemCount: children.length,
            itemBuilder: (context, index) {
              final child = children[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ChildSummaryCard(
                  child: child,
                  onEdit: () => _editChild(context, child),
                  onDelete: () => _confirmDelete(context, ref, child),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _editChild(BuildContext context, Child child) {
    context.push(AppRoutes.parentChildrenAdd, extra: child);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Child child,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir dependente'),
        content: Text('Deseja remover ${child.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(childrenControllerProvider.notifier).delete(child.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${child.name} removido(a).')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}
