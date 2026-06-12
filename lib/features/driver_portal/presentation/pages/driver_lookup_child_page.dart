import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/repositories/enrollments_repository.dart';
import '../providers/driver_portal_providers.dart';

class DriverLookupChildPage extends ConsumerStatefulWidget {
  const DriverLookupChildPage({super.key});

  @override
  ConsumerState<DriverLookupChildPage> createState() =>
      _DriverLookupChildPageState();
}

class _DriverLookupChildPageState extends ConsumerState<DriverLookupChildPage> {
  final TextEditingController _cpfController = TextEditingController();

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  String _maskCpf(String cpf) {
    if (cpf.length != 11) return cpf;
    return '${cpf.substring(0, 3)}.***.***-${cpf.substring(9)}';
  }

  @override
  Widget build(BuildContext context) {
    final lookupAsync = ref.watch(driverLookupControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar crianca')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _cpfController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: InputDecoration(
                hintText: 'Digite o CPF da crianca',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _cpfController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _cpfController.clear();
                          ref
                              .read(driverLookupControllerProvider.notifier)
                              .clear();
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: lookupAsync.isLoading
                    ? null
                    : () => ref
                          .read(driverLookupControllerProvider.notifier)
                          .search(_cpfController.text),
                icon: lookupAsync.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
                label: const Text('Buscar'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: _buildResult(lookupAsync)),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(AsyncValue<ChildLookupResult?> lookupAsync) {
    return lookupAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(
        message: error.toString(),
        onRetry: () => ref
            .read(driverLookupControllerProvider.notifier)
            .search(_cpfController.text),
      ),
      data: (result) {
        if (result == null) {
          return const _EmptyState(
            message: 'Digite o CPF da crianca para buscar.',
            icon: Icons.child_care_outlined,
          );
        }

        return _ChildResultCard(
          result: result,
          onRequestEnrollment: () async {
            if (result.childId == null) return;
            try {
              await ref
                  .read(driverLookupControllerProvider.notifier)
                  .requestEnrollment(result.childId!);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Matricula solicitada com sucesso!'),
                ),
              );
              _cpfController.clear();
              ref.read(driverLookupControllerProvider.notifier).clear();
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Erro: $e')));
            }
          },
          maskCpf: _maskCpf,
        );
      },
    );
  }
}

class _ChildResultCard extends StatelessWidget {
  const _ChildResultCard({
    required this.result,
    required this.onRequestEnrollment,
    required this.maskCpf,
  });

  final ChildLookupResult result;
  final VoidCallback onRequestEnrollment;
  final String Function(String) maskCpf;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.yellowLight,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: const Icon(
                      Icons.child_care_outlined,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.childName ?? 'Nome nao informado',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (result.schoolName != null &&
                            result.schoolName!.isNotEmpty)
                          Text(
                            result.schoolName!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.slate),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (result.parentName != null && result.parentName!.isNotEmpty)
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Responsavel',
                  value: result.parentName!,
                ),
              if (result.address != null && result.address!.isNotEmpty)
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Endereco',
                  value: result.address!,
                ),
              if (result.shiftName != null && result.shiftName!.isNotEmpty)
                _InfoRow(
                  icon: Icons.access_time_rounded,
                  label: 'Turno',
                  value: result.shiftName!,
                ),
              const SizedBox(height: AppSpacing.lg),
              if (result.isInDebt) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4D6),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: const Color(0xFFE3B23C)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 18),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Crianca com inadimplencia. Verifique antes de solicitar matricula.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (result.hasPendingEnrollment) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: const Color(0xFF8FB4FF)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_top_rounded, size: 18),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Ja existe uma solicitacao de matricula pendente para esta crianca.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: result.hasPendingEnrollment
                      ? null
                      : onRequestEnrollment,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Solicitar matricula'),
                ),
              ),
            ],
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.slate),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.slate),
                ),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.muted),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.slate),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.danger,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.slate),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ],
      ),
    );
  }
}
