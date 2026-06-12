import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../state/activation_controller.dart';
import '../widgets/auth_shell.dart';

class ActivationPage extends ConsumerWidget {
  const ActivationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activationControllerProvider);
    final controller = ref.read(activationControllerProvider.notifier);

    return AuthShell(
      title: 'Ativar conta',
      subtitle:
          'Informe seu e-mail ou CPF e o codigo de 6 digitos enviado para voce.',
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !state.isLoading,
            onChanged: controller.setEmailOrCpf,
            decoration: const InputDecoration(
              labelText: 'E-mail ou CPF',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            enabled: !state.isLoading,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: controller.setCode,
            onSubmitted: (_) async => _submit(context, ref),
            decoration: const InputDecoration(
              labelText: 'Codigo de ativacao',
              prefixIcon: Icon(Icons.lock_outline_rounded),
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          if (state.errorMessage != null)
            AuthInlineFeedback(
              icon: Icons.error_outline_rounded,
              color: const Color(0xFFC62828),
              message: state.errorMessage!,
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
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(state.isLoading ? 'Ativando...' : 'Ativar conta'),
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
    final ok = await ref.read(activationControllerProvider.notifier).submit();
    if (!context.mounted || !ok) return;

    showAppSnackBar(
      context,
      message: 'Conta ativada com sucesso! Faca login para continuar.',
      type: AppFeedbackType.success,
    );

    context.go(AppRoutes.login);
  }
}
