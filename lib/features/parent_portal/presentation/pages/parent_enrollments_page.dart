import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/app_error_reporter.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../../core/presentation/widgets/faixa_enrollment_card.dart';
import '../../../../ui/core/widgets/skeleton_list.dart';
import '../providers/parent_portal_providers.dart';

class ParentEnrollmentsPage extends ConsumerWidget {
  const ParentEnrollmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(enrollmentsControllerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.surfaceSoft,
        appBar: FaixaAppBar.screen(
          title: 'Matrículas',
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              onPressed: () =>
                  ref.read(enrollmentsControllerProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 20),
            ),
          ],
        ),
        body: state.when(
          loading: () => const SkeletonList(),
          error: (error, _) => FaixaErrorState(
            message: AppErrorReporter.messageFor(error),
            onRetry: () =>
                ref.read(enrollmentsControllerProvider.notifier).refresh(),
          ),
          data: (enrollments) {
            if (enrollments.isEmpty) {
              return const FaixaEmptyState(
                message: 'Nenhuma matrícula pendente.',
                icon: Icons.fact_check_rounded,
                subtitle:
                    'Quando um motorista solicitar uma matrícula, ela aparecerá aqui.',
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
                  showActions: true,
                  onAccept: () {
                    HapticFeedback.mediumImpact();
                    ref
                        .read(enrollmentsControllerProvider.notifier)
                        .accept(enrollment.id);
                  },
                  onReject: () {
                    HapticFeedback.mediumImpact();
                    ref
                        .read(enrollmentsControllerProvider.notifier)
                        .reject(enrollment.id);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
