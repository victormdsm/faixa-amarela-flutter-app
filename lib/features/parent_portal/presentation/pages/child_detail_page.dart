import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../../core/presentation/widgets/faixa_delete_child_dialog.dart';
import '../../../../core/presentation/widgets/faixa_section_card.dart';
import '../../../../domain/models/child.dart';
import '../../../../domain/models/enrollment.dart';
import '../../../../features/catalog/data/catalog_repository.dart';
import '../../../../ui/core/widgets/status_pill.dart';
import '../providers/parent_portal_providers.dart';

final _childDetailAddressesProvider = FutureProvider.family
    .autoDispose<List<Map<String, dynamic>>, int>((ref, childId) async {
  final repo = ref.watch(childrenRepositoryProvider);
  return repo.getChildAddresses(childId);
});

final _childDetailEnrollmentProvider = FutureProvider.family
    .autoDispose<Enrollment?, int>((ref, childId) async {
  final repo = ref.watch(enrollmentsRepositoryProvider);
  final active = await repo.getActiveEnrollments();
  return active.where((e) => e.childId == childId).firstOrNull;
});

class ChildDetailPage extends ConsumerWidget {
  const ChildDetailPage({super.key, required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolsAsync = ref.watch(schoolsCatalogProvider);
    final shiftsAsync = ref.watch(shiftsCatalogProvider);
    final addressesAsync = ref.watch(_childDetailAddressesProvider(child.id));
    final enrollmentAsync = ref.watch(_childDetailEnrollmentProvider(child.id));

    final schoolName = schoolsAsync.when(
      loading: () => 'Carregando...',
      error: (error, _) => 'Não informado',
      data: (schools) {
        final school = schools.where((s) => s.id == child.schoolId).firstOrNull;
        return school?.name ?? 'Não informado';
      },
    );

    final shiftName = shiftsAsync.when(
      loading: () => 'Carregando...',
      error: (error, _) => 'Não informado',
      data: (shifts) {
        final shift = shifts.where((s) => s.id == child.shiftId).firstOrNull;
        return shift?.name ?? 'Não informado';
      },
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.surfaceSoft,
        appBar: FaixaAppBar.screen(
          title: 'Detalhes do dependente',
          actions: [
            IconButton(
              tooltip: 'Editar',
              onPressed: () => _editChild(context),
              icon: const Icon(Icons.edit_rounded, size: 20),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _HeaderCard(
              child: child,
              schoolName: schoolName,
              shiftName: shiftName,
            ),
            const SizedBox(height: AppSpacing.lg),
            _AddressSection(addressesAsync: addressesAsync),
            const SizedBox(height: AppSpacing.lg),
            _EnrollmentSection(
              enrollmentAsync: enrollmentAsync,
              onCancelEnrollment: (enrollment) =>
                  _confirmCancelEnrollment(context, ref, enrollment),
            ),
            const SizedBox(height: AppSpacing.xl),
            _ActionButtons(
              onEdit: () => _editChild(context),
              onDelete: () => _confirmDelete(context, ref),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  void _editChild(BuildContext context) {
    context.push(AppRoutes.parentChildrenAdd, extra: child);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    try {
      final confirmed = await showDeleteChildConfirmation(
        context,
        child: child,
        loadActiveEnrollment: () => ref
            .read(childrenControllerProvider.notifier)
            .findActiveEnrollmentForChild(child.id),
      );

      if (!confirmed || !context.mounted) return;

      await ref.read(childrenControllerProvider.notifier).delete(child.id);

      if (context.mounted) {
        showAppSnackBar(
          context,
          message: '${child.name} removido(a).',
          type: AppFeedbackType.warning,
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: 'Erro ao verificar vínculos: ${e.toString()}',
          type: AppFeedbackType.error,
        );
      }
    }
  }

  Future<void> _confirmCancelEnrollment(
    BuildContext context,
    WidgetRef ref,
    Enrollment enrollment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        title: const Text('Cancelar matrícula'),
        content: Text(
          'Deseja cancelar a matrícula de ${child.name} com o motorista '
          '${enrollment.driverName}? O vínculo de transporte será encerrado.',
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
            child: const Text('Cancelar matrícula'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(enrollmentsControllerProvider.notifier)
          .cancel(enrollment.id);
      ref.invalidate(_childDetailEnrollmentProvider(child.id));

      if (context.mounted) {
        showAppSnackBar(
          context,
          message: 'Matrícula cancelada.',
          type: AppFeedbackType.warning,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: 'Erro ao cancelar matrícula: ${e.toString()}',
          type: AppFeedbackType.error,
        );
      }
    }
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.child,
    required this.schoolName,
    required this.shiftName,
  });

  final Child child;
  final String schoolName;
  final String shiftName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FaixaSectionCard(
      child: Column(
        children: [
          AppNetworkAvatar(
            name: child.name,
            imageUrl: child.photoUrl,
            radius: 48,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            child.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.school_rounded,
            label: 'Escola',
            value: schoolName,
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.schedule_rounded,
            label: 'Turno',
            value: shiftName,
          ),
          if (child.isInDebt) ...[
            const SizedBox(height: AppSpacing.md),
            const StatusPill(
              label: 'Inadimplente',
              color: AppColors.danger,
            ),
          ],
        ],
      ),
    );
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
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.slate,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AddressSection extends StatelessWidget {
  const _AddressSection({required this.addressesAsync});

  final AsyncValue<List<Map<String, dynamic>>> addressesAsync;

  @override
  Widget build(BuildContext context) {
    return FaixaSectionCard(
      icon: Icons.location_on_rounded,
      title: 'Endereço',
      child: addressesAsync.when(
        loading: () => const SizedBox(
          height: 40,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => AppInfoBanner(
          message: 'Erro ao carregar endereço: $error',
          icon: Icons.error_outline_rounded,
          color: AppColors.danger,
        ),
        data: (addresses) {
          if (addresses.isEmpty) {
            return Text(
              'Nenhum endereço cadastrado.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.slate,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: addresses.map((addr) {
              final street = (addr['street'] ?? '').toString();
              final number = (addr['number'] ?? '').toString();
              final complement = (addr['reference'] ?? '').toString();
              final zipcode = (addr['zipcode'] ?? '').toString();

              final parts = <String>[
                if (street.isNotEmpty) street,
                if (number.isNotEmpty) number,
                if (complement.isNotEmpty) complement,
                if (zipcode.isNotEmpty) 'CEP: $zipcode',
              ];

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.home_rounded,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        parts.join(', '),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _EnrollmentSection extends StatelessWidget {
  const _EnrollmentSection({
    required this.enrollmentAsync,
    this.onCancelEnrollment,
  });

  final AsyncValue<Enrollment?> enrollmentAsync;
  final ValueChanged<Enrollment>? onCancelEnrollment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FaixaSectionCard(
      icon: Icons.fact_check_rounded,
      title: 'Matrícula e transporte',
      child: enrollmentAsync.when(
        loading: () => const SizedBox(
          height: 40,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => AppInfoBanner(
          message: 'Erro ao carregar matrícula: $error',
          icon: Icons.error_outline_rounded,
          color: AppColors.danger,
        ),
        data: (enrollment) {
          if (enrollment == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sem matrícula ativa',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.slate,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const StatusPill(
                  label: 'Aguardando vínculo com motorista',
                  color: AppColors.warning,
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                icon: Icons.person_outline_rounded,
                label: 'Motorista',
                value: enrollment.driverName,
              ),
              const SizedBox(height: AppSpacing.sm),
              _InfoRow(
                icon: Icons.directions_car_rounded,
                label: 'Van',
                value: enrollment.vanPlate,
              ),
              const SizedBox(height: AppSpacing.sm),
              _InfoRow(
                icon: Icons.school_rounded,
                label: 'Escola',
                value: enrollment.schoolName,
              ),
              const SizedBox(height: AppSpacing.md),
              StatusPill.fromStatus(enrollment.status),
              if (enrollment.status == EnrollmentStatus.active &&
                  onCancelEnrollment != null) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  onPressed: () => onCancelEnrollment!(enrollment),
                  icon: const Icon(Icons.cancel_rounded),
                  label: const Text('Cancelar matrícula'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Editar'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.surface,
            ),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Excluir'),
          ),
        ),
      ],
    );
  }
}
