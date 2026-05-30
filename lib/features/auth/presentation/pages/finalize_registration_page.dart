import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../state/finalize_registration_controller.dart';
import '../widgets/auth_shell.dart';

class FinalizeRegistrationPage extends ConsumerWidget {
  const FinalizeRegistrationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(finalizeRegistrationControllerProvider);
    final controller = ref.read(
      finalizeRegistrationControllerProvider.notifier,
    );
    final theme = Theme.of(context);

    return AuthShell(
      title: 'Finalizar cadastro',
      subtitle:
          'Informe e-mail ou CPF para receber (ou reenviar) o link de ativacao da sua conta.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            enabled: !state.isLoading,
            onChanged: controller.setLogin,
            onSubmitted: (_) async => _submit(context, ref),
            decoration: const InputDecoration(
              labelText: 'E-mail ou CPF',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: state.errorMessage != null
                ? AuthInlineFeedback(
                    key: const ValueKey('error'),
                    icon: Icons.error_outline_rounded,
                    color: AppColors.danger,
                    message: state.errorMessage!,
                  )
                : state.successMessage != null
                ? AuthInlineFeedback(
                    key: const ValueKey('success'),
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    message: state.successMessage!,
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: state.isLoading
                ? null
                : () async => _submit(context, ref),
            icon: state.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.mark_email_read_outlined),
            label: Text(
              state.isLoading ? 'Enviando...' : 'Enviar link de finalizacao',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.yellowDark.withValues(alpha: 0.24),
              ),
            ),
            child: Text(
              'A conta do responsavel e unica. Se mudar de tio da van, ela pode ser transferida para outro motorista apos desvinculo e novo vinculo pelo CPF.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.slate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Voltar para login'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(finalizeRegistrationControllerProvider.notifier)
        .submit();
    if (!context.mounted || !ok) return;

    showAppSnackBar(
      context,
      message: 'Solicitacao de finalizacao enviada.',
      type: AppFeedbackType.success,
    );
  }
}
