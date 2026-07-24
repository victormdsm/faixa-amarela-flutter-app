import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
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
          'Informe o e-mail cadastrado. Vamos enviar as instruções de recuperação.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthTextField(
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            enabled: !state.isLoading,
            onChanged: controller.setEmail,
            onSubmitted: (_) async => _submit(context, ref),
            labelText: 'E-mail',
            prefixIcon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: AppSpacing.xl),
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
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: state.isLoading
                ? null
                : () async => _submit(context, ref),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.yellow.withValues(
                alpha: 0.4,
              ),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: state.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Enviar recuperação'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.resetPassword),
            icon: Icon(
              Icons.password_rounded,
              color: AppColors.ink.withValues(alpha: 0.55),
              size: 20,
            ),
            label: const Text('Já tenho um código'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.ink.withValues(alpha: 0.7),
              minimumSize: const Size.fromHeight(44),
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.ink.withValues(alpha: 0.55),
              size: 20,
            ),
            label: const Text('Voltar para login'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.ink.withValues(alpha: 0.7),
              minimumSize: const Size.fromHeight(44),
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
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
      message: 'Código enviado! Verifique seu e-mail.',
      type: AppFeedbackType.success,
    );

    // Avanca automaticamente para a tela de redefinicao de senha.
    context.push(AppRoutes.resetPassword);
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    required this.onChanged,
    this.onSubmitted,
    required this.labelText,
    required this.prefixIcon,
  });

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final String labelText;
  final IconData prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: AppColors.ink,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.ink.withValues(alpha: 0.55),
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: AppColors.ink.withValues(alpha: 0.4),
          size: 22,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.yellow, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
      ),
    );
  }
}
