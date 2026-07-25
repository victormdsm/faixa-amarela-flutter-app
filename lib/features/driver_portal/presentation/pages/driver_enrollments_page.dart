import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../../core/presentation/widgets/faixa_enrollment_card.dart';
import '../../../../domain/models/enrollment.dart';
import '../../../../ui/core/widgets/skeleton_list.dart';
import '../providers/driver_portal_providers.dart';

class DriverEnrollmentsPage extends ConsumerWidget {
  const DriverEnrollmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync = ref.watch(driverEnrollmentsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      appBar: FaixaAppBar.screen(
        title: 'Matriculas',
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => ref
                .read(driverEnrollmentsControllerProvider.notifier)
                .refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: enrollmentsAsync.when(
        loading: () => const SkeletonList(),
        error: (error, _) => FaixaErrorState(
          message: error.toString(),
          onRetry: () =>
              ref.read(driverEnrollmentsControllerProvider.notifier).refresh(),
        ),
        data: (enrollments) {
          if (enrollments.isEmpty) {
            return const FaixaEmptyState(
              message: 'Voce ainda nao tem matriculas.',
              icon: Icons.school_outlined,
              subtitle:
                  'Quando vincular criancas ao seu veiculo, elas aparecerao aqui.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              100,
            ),
            itemCount: enrollments.length,
            itemBuilder: (context, index) {
              final enrollment = enrollments[index];
              return FaixaEnrollmentCard(
                key: ValueKey('enrollment_${enrollment.id}'),
                enrollment: enrollment,
                actions: _buildActions(context, ref, enrollment),
              );
            },
          );
        },
      ),
    );
  }

  /// Ação "Desvincular" disponível para matrículas ativas e solicitações
  /// pendentes (o motorista pode desistir de uma solicitação não aceita).
  List<Widget>? _buildActions(
    BuildContext context,
    WidgetRef ref,
    Enrollment enrollment,
  ) {
    final canUnlink =
        enrollment.status == EnrollmentStatus.active ||
        enrollment.status == EnrollmentStatus.pending;
    if (!canUnlink) return null;

    return [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _confirmUnlink(context, ref, enrollment),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
          ),
          icon: const Icon(Icons.link_off_rounded, size: 18),
          label: const Text('Desvincular'),
        ),
      ),
    ];
  }

  Future<void> _confirmUnlink(
    BuildContext context,
    WidgetRef ref,
    Enrollment enrollment,
  ) async {
    final childName = enrollment.childName.isNotEmpty
        ? enrollment.childName
        : 'esta criança';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        title: const Text('Desvincular criança'),
        content: Text(
          'Deseja desvincular $childName? A criança sairá da sua lista e '
          'não aparecerá mais nas rotas. O responsável será informado.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.surface,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(driverEnrollmentsControllerProvider.notifier)
          .cancel(enrollment.id);

      if (context.mounted) {
        showAppSnackBar(
          context,
          message: 'Matrícula desvinculada.',
          type: AppFeedbackType.warning,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: 'Erro ao desvincular matrícula: ${e.toString()}',
          type: AppFeedbackType.error,
        );
      }
    }
  }
}
