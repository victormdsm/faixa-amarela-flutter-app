import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/app_error_reporter.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/e2e_keys.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../../domain/repositories/enrollments_repository.dart';
import '../providers/driver_portal_providers.dart';

class DriverLookupChildPage extends ConsumerStatefulWidget {
  const DriverLookupChildPage({super.key});

  @override
  ConsumerState<DriverLookupChildPage> createState() =>
      _DriverLookupChildPageState();
}

class _DriverLookupChildPageState extends ConsumerState<DriverLookupChildPage> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// O controller converte `found == false` em erro genérico; distinguimos o
  /// caso "criança não encontrada" para exibir empty state em vez de erro.
  bool _isNotFoundError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('não encontrada') ||
        message.contains('nao encontrada') ||
        message.contains('not found');
  }

  /// F4 multi-vínculo: exige confirmação explícita do motorista antes de
  /// solicitar matrícula de criança que já tem vínculo ativo com outro
  /// motorista.
  Future<bool> _confirmMultiDriverWarning(ChildLookupResult result) async {
    final names = result.activeDriverNames.isNotEmpty
        ? result.activeDriverNames.join(', ')
        : 'outro motorista';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        title: const Text('Vínculo ativo existente'),
        content: Text(
          'Esta criança já possui vínculo ativo com $names. '
          'Deseja continuar e solicitar mesmo assim?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Solicitar mesmo assim'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final lookupAsync = ref.watch(driverLookupControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      appBar: FaixaAppBar.screen(
        title: 'Buscar criança',
        showBack: Navigator.of(context).canPop(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: E2EKeys.driverCpfInput,
              controller: _codeController,
              keyboardType: TextInputType.text,
              inputFormatters: [LengthLimitingTextInputFormatter(36)],
              decoration: InputDecoration(
                labelText: 'Código da criança',
                hintText:
                    'Peça ao responsável o código que aparece no perfil da criança no app',
                helperText: 'Perfil da criança → código para compartilhar',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _codeController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _codeController.clear();
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
                key: E2EKeys.driverSearchChildButton,
                onPressed: lookupAsync.isLoading
                    ? null
                    : () => ref
                          .read(driverLookupControllerProvider.notifier)
                          .search(_codeController.text),
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
      error: (error, _) {
        if (_isNotFoundError(error)) {
          return const _ChildNotFoundState();
        }
        return FaixaErrorState(
          message: AppErrorReporter.messageFor(error),
          onRetry: () => ref
              .read(driverLookupControllerProvider.notifier)
              .search(_codeController.text),
        );
      },
      data: (result) {
        if (result == null) {
          return const FaixaEmptyState(
            message: 'Digite o código da criança para buscar.',
            icon: Icons.child_care_rounded,
            subtitle:
                'O responsável encontra o código no perfil da criança no aplicativo.',
          );
        }

        if (!result.found || result.childId == null) {
          return const _ChildNotFoundState();
        }

        return _ChildResultCard(
          result: result,
          onRequestEnrollment: () async {
            final childUuid = result.childUuid;
            if (childUuid == null) return;
            if (result.hasActiveEnrollmentWithOtherDriver) {
              final confirmed = await _confirmMultiDriverWarning(result);
              if (!confirmed || !mounted) return;
            }
            try {
              await ref
                  .read(driverLookupControllerProvider.notifier)
                  .requestEnrollment(childUuid);
              if (!mounted) return;
              showAppSnackBar(
                context,
                message: 'Matrícula solicitada com sucesso!',
                type: AppFeedbackType.success,
              );
              _codeController.clear();
              ref.read(driverLookupControllerProvider.notifier).clear();
            } catch (e) {
              if (!mounted) return;
              final message = e is ApiException
                  ? e.message
                  : 'Não foi possível solicitar a matrícula. Tente novamente.';
              showAppSnackBar(
                context,
                message: message,
                type: AppFeedbackType.error,
              );
            }
          },
        );
      },
    );
  }
}

/// Estado exibido quando o backend responde `found == false` (ou nulo):
/// nenhuma criança localizada para o código informado.
class _ChildNotFoundState extends StatelessWidget {
  const _ChildNotFoundState();

  @override
  Widget build(BuildContext context) {
    return const FaixaEmptyState(
      message: 'Nenhuma criança encontrada para este código.',
      icon: Icons.person_search_rounded,
      subtitle:
          'Verifique se o código informado é o da criança e se o responsável já cadastrou o dependente.',
    );
  }
}

class _ChildResultCard extends StatelessWidget {
  const _ChildResultCard({
    required this.result,
    required this.onRequestEnrollment,
  });

  final ChildLookupResult result;
  final VoidCallback onRequestEnrollment;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
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
                      Icons.child_care_rounded,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.childName ?? 'Nome não informado',
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
                  label: 'Responsável',
                  value: result.parentName!,
                ),
              if (result.address != null && result.address!.isNotEmpty)
                _InfoRow(
                  icon: Icons.location_on_rounded,
                  label: 'Endereço',
                  value: result.address!,
                ),
              if (result.districtName != null &&
                  result.districtName!.isNotEmpty)
                _InfoRow(
                  icon: Icons.location_city_rounded,
                  label: 'Bairro',
                  value: result.districtName!,
                ),
              if (result.shiftName != null && result.shiftName!.isNotEmpty)
                _InfoRow(
                  icon: Icons.access_time_rounded,
                  label: 'Turno',
                  value: result.shiftName!,
                ),
              const SizedBox(height: AppSpacing.lg),
              if (result.isInDebt) ...[
                AppInfoBanner(
                  message:
                      'Criança com inadimplência. Verifique antes de solicitar matrícula.',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.yellowDark,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (result.hasPendingEnrollment) ...[
                AppInfoBanner(
                  message:
                      'Já existe uma solicitação de matrícula pendente para esta criança.',
                  icon: Icons.hourglass_top_rounded,
                  color: AppColors.info,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (result.hasActiveEnrollmentWithOtherDriver) ...[
                AppInfoBanner(
                  message:
                      'Esta criança já possui vínculo ativo com ${result.activeDriverNames.isNotEmpty ? result.activeDriverNames.join(', ') : 'outro motorista'}. '
                      'Ao solicitar, você precisará confirmar que deseja continuar.',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.yellowDark,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: E2EKeys.driverRequestEnrollmentButton,
                  onPressed: result.hasPendingEnrollment
                      ? null
                      : onRequestEnrollment,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Solicitar matrícula'),
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
