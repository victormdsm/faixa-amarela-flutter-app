import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/e2e_keys.dart';
import '../state/login_controller.dart';
import 'login_anonymous_search.dart';
import 'login_role_selector.dart';
import 'login_signup_prompt.dart';

/// Formulário de login com seleção de perfil, e-mail/senha e ações.
class LoginForm extends ConsumerWidget {
  const LoginForm({super.key, required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoginRoleSelector(
          selectedRole: state.role,
          enabled: !state.isLoading,
          onRoleChanged: controller.setRole,
        ),
        const SizedBox(height: AppSpacing.xl),
        _AuthTextField(
          key: E2EKeys.emailInput,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !state.isLoading,
          onChanged: controller.setEmail,
          labelText: 'E-mail',
          prefixIcon: Icons.mail_outline_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        _AuthTextField(
          key: E2EKeys.passwordInput,
          obscureText: state.obscurePassword,
          textInputAction: TextInputAction.done,
          enabled: !state.isLoading,
          onChanged: controller.setPassword,
          onSubmitted: (_) => onSubmit(),
          labelText: 'Senha',
          prefixIcon: Icons.lock_outline_rounded,
          suffixIcon: IconButton(
            onPressed: state.isLoading
                ? null
                : controller.togglePasswordVisibility,
            tooltip: state.obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
            icon: Icon(
              state.obscurePassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: AppColors.ink.withValues(alpha: 0.45),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 16,
            children: [
              TextButton(
                onPressed: state.isLoading
                    ? null
                    : () => context.push(AppRoutes.forgotPassword),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.yellow,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('Esqueci minha senha'),
              ),
              TextButton(
                onPressed: state.isLoading
                    ? null
                    : () => context.push(AppRoutes.finalizeRegistration),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.ink.withValues(
                    alpha: 0.6,
                  ),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('Finalizar cadastro'),
              ),
            ],
          ),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          FaixaErrorBanner(message: state.errorMessage!),
        ],
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          key: E2EKeys.loginButton,
          onPressed: state.isLoading ? null : onSubmit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.yellow,
            foregroundColor: AppColors.ink,
            disabledBackgroundColor: AppColors.yellow.withValues(
              alpha: 0.4,
            ),
            disabledForegroundColor: AppColors.ink.withValues(alpha: 0.5),
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
                    color: AppColors.ink,
                  ),
                )
              : const Text('Entrar'),
        ),
        const SizedBox(height: AppSpacing.md),
        LoginSignUpPrompt(
          enabled: !state.isLoading,
          onCreateAccount: () => context.push(AppRoutes.parentSignUp),
        ),
        const SizedBox(height: AppSpacing.sm),
        LoginAnonymousSearch(
          enabled: !state.isLoading,
          onSearch: () => context.push(AppRoutes.searchTransport),
        ),
      ],
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    super.key,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.obscureText = false,
    required this.onChanged,
    this.onSubmitted,
    required this.labelText,
    required this.prefixIcon,
    this.suffixIcon,
  });

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool obscureText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final String labelText;
  final IconData prefixIcon;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      enabled: enabled,
      obscureText: obscureText,
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
        suffixIcon: suffixIcon,
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
