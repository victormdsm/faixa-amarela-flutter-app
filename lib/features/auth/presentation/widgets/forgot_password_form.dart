import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../state/forgot_password_controller.dart';
import 'auth_shell.dart';

class ForgotPasswordForm extends ConsumerWidget {
  const ForgotPasswordForm({super.key, required this.onResetCodeRequested});

  final VoidCallback onResetCodeRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final controller = ref.read(forgotPasswordControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          enabled: !state.isLoading,
          onChanged: controller.setEmail,
          onSubmitted: (_) async => _submit(context, ref),
          decoration: const InputDecoration(
            labelText: 'E-mail',
            prefixIcon: Icon(Icons.mail_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
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
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: state.isLoading ? null : () async => _submit(context, ref),
          icon: state.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.mark_email_read_rounded),
          label: Text(state.isLoading ? 'Enviando...' : 'Enviar recuperação'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: state.isLoading ? null : onResetCodeRequested,
          icon: const Icon(Icons.vpn_key_rounded),
          label: const Text('Já tenho um código'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Voltar para login'),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .submit();
    if (!context.mounted || !ok) return;

    showAppSnackBar(
      context,
      message: 'Solicitação de recuperação enviada.',
      type: AppFeedbackType.success,
    );

    onResetCodeRequested();
  }
}
