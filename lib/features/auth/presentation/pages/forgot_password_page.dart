import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/widgets/app_feedback.dart';
import '../state/forgot_password_controller.dart';
import '../widgets/auth_shell.dart';

class ForgotPasswordPage extends ConsumerWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final controller = ref.read(forgotPasswordControllerProvider.notifier);
    return AuthShell(
      title: 'Recuperar senha',
      subtitle:
          'Informe o e-mail cadastrado. Vamos enviar as instrucoes de recuperacao.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            enabled: !state.isLoading,
            onChanged: controller.setEmail,
            onSubmitted: (_) async {
              await _submit(context, ref);
            },
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: state.errorMessage != null
                ? AuthInlineFeedback(
                    key: const ValueKey('error'),
                    icon: Icons.error_outline_rounded,
                    color: const Color(0xFFC62828),
                    message: state.errorMessage!,
                  )
                : state.successMessage != null
                ? AuthInlineFeedback(
                    key: const ValueKey('success'),
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFF1F8A4C),
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
            label: Text(state.isLoading ? 'Enviando...' : 'Enviar recuperacao'),
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
        .read(forgotPasswordControllerProvider.notifier)
        .submit();
    if (!context.mounted || !ok) return;

    showAppSnackBar(
      context,
      message: 'Solicitacao de recuperacao enviada.',
      type: AppFeedbackType.success,
    );
  }
}
