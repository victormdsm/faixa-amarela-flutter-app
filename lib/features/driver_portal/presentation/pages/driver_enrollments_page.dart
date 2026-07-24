import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../../core/presentation/widgets/faixa_enrollment_card.dart';
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
              );
            },
          );
        },
      ),
    );
  }
}
