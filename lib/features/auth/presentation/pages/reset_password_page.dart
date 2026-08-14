import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../state/forgot_password_controller.dart';
import '../state/reset_password_controller.dart';
import '../widgets/auth_shell.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final resetController = ref.read(
          resetPasswordControllerProvider.notifier,
        );
        final token = GoRouterState.of(context).uri.queryParameters['token'];
        if (token != null && token.isNotEmpty) {
          resetController.setToken(token);
        }
        if (ref.read(resetPasswordControllerProvider).email.trim().isEmpty) {
          final forgotEmail = ref.read(forgotPasswordControllerProvider).email;
          if (forgotEmail.trim().isNotEmpty) {
            resetController.setEmail(forgotEmail);
          }
        }
      } catch (_) {
        // Running outside a GoRouter context (e.g. unit tests) — ignore.
      }
    });
  }

  @override
  void dispose() {
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordControllerProvider);
    final controller = ref.read(resetPasswordControllerProvider.notifier);

    return AuthShell(
      title: 'Redefinir senha',
      subtitle:
          'Informe o código de 6 dígitos enviado por e-mail e escolha uma nova senha.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthTextField(
            controller: TextEditingController(text: state.email)
              ..selection = TextSelection.collapsed(offset: state.email.length),
            enabled: !state.isLoading,
            textInputAction: TextInputAction.next,
            onChanged: controller.setEmail,
            labelText: 'E-mail cadastrado',
            prefixIcon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          _AuthTextField(
            controller: TextEditingController(text: state.token)
              ..selection = TextSelection.collapsed(offset: state.token.length),
            enabled: !state.isLoading,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            onChanged: controller.setToken,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
            labelText: 'Código de recuperação',
            prefixIcon: Icons.vpn_key_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          _AuthTextField(
            focusNode: _passwordFocus,
            obscureText: state.obscurePassword,
            enabled: !state.isLoading,
            textInputAction: TextInputAction.next,
            onChanged: controller.setPassword,
            onSubmitted: (_) => _confirmFocus.requestFocus(),
            labelText: 'Nova senha',
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                state.obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.ink.withValues(alpha: 0.45),
                size: 22,
              ),
              onPressed: controller.togglePasswordVisibility,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PasswordRequirements(password: state.password),
          const SizedBox(height: AppSpacing.md),
          _AuthTextField(
            focusNode: _confirmFocus,
            obscureText: state.obscurePasswordConfirmation,
            enabled: !state.isLoading,
            textInputAction: TextInputAction.done,
            onChanged: controller.setPasswordConfirmation,
            onSubmitted: (_) => _submit(),
            labelText: 'Confirmar nova senha',
            prefixIcon: Icons.lock_person_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                state.obscurePasswordConfirmation
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.ink.withValues(alpha: 0.45),
                size: 22,
              ),
              onPressed: controller.togglePasswordConfirmationVisibility,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: state.errorMessage != null
                ? FaixaErrorBanner(
                    key: const ValueKey('error'),
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
            onPressed: state.isLoading || !state.canSubmit ? null : _submit,
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
                : const Text('Redefinir senha'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.login),
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
          Center(
            child: TextButton(
              onPressed: state.isLoading
                  ? null
                  : () => context.pushReplacement(AppRoutes.forgotPassword),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.ink.withValues(alpha: 0.6),
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Não recebeu o código? Reenviar'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final ok = await ref
        .read(resetPasswordControllerProvider.notifier)
        .submit();
    if (!mounted || !ok) return;

    showAppSnackBar(
      context,
      message: 'Senha redefinida com sucesso! Faça login com a nova senha.',
      type: AppFeedbackType.success,
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) context.go(AppRoutes.login);
    });
  }
}

class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    Widget item(String label, bool met) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.circle_rounded,
          size: 12,
          color: met
              ? AppColors.success
              : AppColors.ink.withValues(alpha: 0.45),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: met
                ? AppColors.success
                : AppColors.ink.withValues(alpha: 0.55),
            fontWeight: met ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        item('Mínimo 6 caracteres', password.length >= 6),
        item('1 letra', password.contains(RegExp(r'[A-Za-z]'))),
        item('1 número', password.contains(RegExp(r'[0-9]'))),
      ],
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    this.controller,
    this.focusNode,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.obscureText = false,
    required this.onChanged,
    this.onSubmitted,
    required this.labelText,
    required this.prefixIcon,
    this.suffixIcon,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
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
      controller: controller,
      focusNode: focusNode,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
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
