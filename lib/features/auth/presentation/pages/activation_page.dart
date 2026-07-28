import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../state/activation_controller.dart';
import '../widgets/auth_shell.dart';

class ActivationPage extends ConsumerStatefulWidget {
  const ActivationPage({super.key});

  @override
  ConsumerState<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends ConsumerState<ActivationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final params = GoRouterState.of(context).uri.queryParameters;
        final token = params['token'];
        if (token != null && token.isNotEmpty) {
          final digits = token.replaceAll(RegExp(r'[^0-9]'), '');
          if (digits.length == 6) {
            ref.read(activationControllerProvider.notifier).setCode(digits);
          }
        }
        final email = params['email'];
        if (email != null && email.isNotEmpty) {
          ref.read(activationControllerProvider.notifier).setEmailOrCpf(email);
        }
      } catch (_) {
        // Running outside a GoRouter context (e.g. unit tests) — ignore.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activationControllerProvider);
    final controller = ref.read(activationControllerProvider.notifier);

    return AuthShell(
      title: 'Ativar conta',
      subtitle:
          'Informe seu e-mail ou CPF e o código de 6 dígitos enviado para você.',
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthTextField(
            controller: TextEditingController(text: state.emailOrCpf)
              ..selection = TextSelection.collapsed(
                offset: state.emailOrCpf.length,
              ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !state.isLoading,
            onChanged: controller.setEmailOrCpf,
            labelText: 'E-mail ou CPF',
            prefixIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          _AuthTextField(
            controller: TextEditingController(text: state.code)
              ..selection = TextSelection.collapsed(offset: state.code.length),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            enabled: !state.isLoading,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: controller.setCode,
            onSubmitted: (_) async => _submit(),
            labelText: 'Código de ativação',
            prefixIcon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (state.errorMessage != null)
            FaixaErrorBanner(message: state.errorMessage!),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: state.isLoading || !state.canSubmit ? null : _submit,
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
                : const Text('Ativar conta'),
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
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final ok = await ref.read(activationControllerProvider.notifier).submit();
    if (!mounted || !ok) return;

    showAppSnackBar(
      context,
      message: 'Conta ativada com sucesso! Faça login para continuar.',
      type: AppFeedbackType.success,
    );

    context.go(AppRoutes.login);
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.maxLength,
    this.inputFormatters,
    required this.onChanged,
    this.onSubmitted,
    required this.labelText,
    required this.prefixIcon,
  });

  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final String labelText;
  final IconData prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      enabled: enabled,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
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
        counterText: '',
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
