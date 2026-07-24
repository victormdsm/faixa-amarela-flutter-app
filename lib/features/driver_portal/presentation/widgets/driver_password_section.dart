import 'package:flutter/material.dart';

/// Campos de alteração de senha do admin nas configurações do motorista.
class DriverPasswordSection extends StatelessWidget {
  const DriverPasswordSection({
    super.key,
    required this.isSaving,
    this.currentPasswordController,
    required this.passwordController,
    required this.passwordConfirmController,
    this.showCurrentPassword = true,
  });

  final bool isSaving;
  final TextEditingController? currentPasswordController;
  final TextEditingController passwordController;
  final TextEditingController passwordConfirmController;
  final bool showCurrentPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showCurrentPassword) ...[
          TextFormField(
            controller: currentPasswordController,
            enabled: !isSaving,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Senha atual',
              prefixIcon: Icon(Icons.lock_person_outlined),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextFormField(
          controller: passwordController,
          enabled: !isSaving,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Nova senha (opcional)',
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: passwordConfirmController,
          enabled: !isSaving,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Confirmar nova senha',
            prefixIcon: Icon(Icons.lock_reset_outlined),
          ),
        ),
      ],
    );
  }
}
