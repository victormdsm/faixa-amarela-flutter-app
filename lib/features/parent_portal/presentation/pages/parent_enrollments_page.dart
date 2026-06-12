import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../domain/models/enrollment.dart';
import '../../../../ui/core/widgets/skeleton_list.dart';
import '../../../../ui/core/widgets/status_pill.dart';
import '../providers/parent_portal_providers.dart';

class ParentEnrollmentsPage extends ConsumerWidget {
  const ParentEnrollmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(enrollmentsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matriculas pendentes'),
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
        error: (error, _) => AppErrorState(
          message: error is Exception
              ? error.toString()
              : 'Erro ao carregar matriculas.',
          onRetry: () =>
              ref.read(enrollmentsControllerProvider.notifier).refresh(),
        ),
        data: (enrollments) {
          if (enrollments.isEmpty) {
            return const AppEmptyState(
              message: 'Nenhuma matricula pendente.',
              icon: Icons.fact_check_outlined,
              subtitle:
                  'Quando um motorista solicitar uma matricula, ela aparecera aqui.',
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
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _EnrollmentCard(
                  enrollment: enrollment,
                  onAccept: () => ref
                      .read(enrollmentsControllerProvider.notifier)
                      .accept(enrollment.id),
                  onReject: () => ref
                      .read(enrollmentsControllerProvider.notifier)
                      .reject(enrollment.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EnrollmentCard extends StatefulWidget {
  const _EnrollmentCard({
    required this.enrollment,
    this.onAccept,
    this.onReject,
  });

  final Enrollment enrollment;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  State<_EnrollmentCard> createState() => _EnrollmentCardState();
}

class _EnrollmentCardState extends State<_EnrollmentCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enrollment = widget.enrollment;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    enrollment.childName.isNotEmpty
                        ? enrollment.childName
                        : 'Dependente',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StatusPill.fromStatus(EnrollmentStatus.pending),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              enrollment.schoolName.isNotEmpty
                  ? enrollment.schoolName
                  : 'Escola nao informada',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.slate,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Motorista',
                    value: enrollment.driverName,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _InfoRow(
                    icon: Icons.directions_car_outlined,
                    label: 'Van',
                    value: enrollment.vanPlate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isProcessing || widget.onAccept == null
                        ? null
                        : () => _run(widget.onAccept!),
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Aceitar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing || widget.onReject == null
                        ? null
                        : () => _run(widget.onReject!),
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Recusar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _run(VoidCallback action) async {
    setState(() => _isProcessing = true);
    try {
      action();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
