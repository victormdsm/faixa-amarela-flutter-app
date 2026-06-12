import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../state/reset_password_controller.dart';
import '../widgets/auth_shell.dart';

class ResetPasswordPage extends ConsumerWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(resetPasswordControllerProvider);
    final controller = ref.read(resetPasswordControllerProvider.notifier);

    return AuthShell(
      title: 'Redefinir senha',
      subtitle: 'Informe o token recebido por e-mail e sua nova senha.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            enabled: !state.isLoading,
            onChanged: controller.setToken,
            decoration: const InputDecoration(
              labelText: 'Token',
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            obscureText: true,
            enabled: !state.isLoading,
            onChanged: controller.setPassword,
            decoration: const InputDecoration(
              labelText: 'Nova senha',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            obscureText: true,
            enabled: !state.isLoading,
            onChanged: controller.setPasswordConfirmation,
            decoration: const InputDecoration(
              labelText: 'Confirmar nova senha',
              prefixIcon: Icon(Icons.lock_person_outlined),
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
            onPressed: state.isLoading || !state.canSubmit
                ? null
                : () async => _submit(context, ref),
            icon: state.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(state.isLoading ? 'Salvando...' : 'Redefinir senha'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.login),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Voltar para login'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(resetPasswordControllerProvider.notifier)
        .submit();
    if (!context.mounted || !ok) return;

    showAppSnackBar(
      context,
      message: 'Senha redefinida com sucesso! Faca login com a nova senha.',
      type: AppFeedbackType.success,
    );

    // Volta para login apos sucesso
    Future.delayed(const Duration(seconds: 1), () {
      if (context.mounted) context.go(AppRoutes.login);
    });
  }
}
