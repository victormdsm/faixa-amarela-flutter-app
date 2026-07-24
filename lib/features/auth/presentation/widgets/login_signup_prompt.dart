import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// CTA de criação de conta na tela de login.
///
/// Versão simplificada alinhada ao design Stitch: texto + botão outlined.
class LoginSignUpPrompt extends StatelessWidget {
  const LoginSignUpPrompt({
    super.key,
    required this.onCreateAccount,
    this.enabled = true,
  });

  final VoidCallback onCreateAccount;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: enabled ? onCreateAccount : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.yellow,
            side: const BorderSide(color: AppColors.yellow),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: const Text('Criar conta'),
        ),
      ],
    );
  }
}
