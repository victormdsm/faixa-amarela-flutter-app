import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/app_error_reporter.dart';
import '../providers/auth_providers.dart';
import 'auth_shell.dart';

class ResetPasswordCodeDialog extends ConsumerStatefulWidget {
  const ResetPasswordCodeDialog({super.key, required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  ConsumerState<ResetPasswordCodeDialog> createState() =>
      _ResetPasswordCodeDialogState();
}

class _ResetPasswordCodeDialogState
    extends ConsumerState<ResetPasswordCodeDialog> {
  String _email = '';
  String _token = '';
  String _password = '';
  String _passwordConfirmation = '';
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get _canSubmit {
    return _email.trim().isNotEmpty &&
        _token.trim().isNotEmpty &&
        _password.isNotEmpty &&
        _passwordConfirmation.isNotEmpty &&
        !_isLoading;
  }

  Future<void> _submit() async {
    if (_email.trim().isEmpty) {
      setState(() => _errorMessage = 'Informe o e-mail cadastrado.');
      return;
    }
    if (_token.trim().isEmpty) {
      setState(() => _errorMessage = 'Informe o código recebido por e-mail.');
      return;
    }
    if (_password.isEmpty) {
      setState(() => _errorMessage = 'Informe a nova senha.');
      return;
    }
    if (_password.length < 6) {
      setState(
        () => _errorMessage = 'A nova senha deve ter pelo menos 6 caracteres.',
      );
      return;
    }
    if (_password != _passwordConfirmation) {
      setState(() => _errorMessage = 'As senhas não coincidem.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ref
          .read(resetPasswordUseCaseProvider)
          .call(
            email: _email.trim(),
            token: _token.trim(),
            password: _password,
            passwordConfirmation: _passwordConfirmation,
          );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _successMessage = 'Senha redefinida com sucesso!';
      });
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      widget.onSuccess();
    } on Exception catch (e) {
      if (!mounted) return;
      final message = AppErrorReporter.messageFor(e);
      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock_reset_rounded),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: Text('Redefinir senha')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Digite o e-mail cadastrado, o código enviado para o seu e-mail e a nova senha.',
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              enabled: !_isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onChanged: (value) => setState(() {
                _email = value;
                _errorMessage = null;
              }),
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              enabled: !_isLoading,
              textInputAction: TextInputAction.next,
              onChanged: (value) => setState(() {
                _token = value;
                _errorMessage = null;
              }),
              decoration: const InputDecoration(
                labelText: 'Código',
                prefixIcon: Icon(Icons.vpn_key_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              obscureText: true,
              enabled: !_isLoading,
              textInputAction: TextInputAction.next,
              onChanged: (value) => setState(() {
                _password = value;
                _errorMessage = null;
              }),
              decoration: const InputDecoration(
                labelText: 'Nova senha',
                prefixIcon: Icon(Icons.lock_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              obscureText: true,
              enabled: !_isLoading,
              textInputAction: TextInputAction.done,
              onChanged: (value) => setState(() {
                _passwordConfirmation = value;
                _errorMessage = null;
              }),
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Confirmar nova senha',
                prefixIcon: Icon(Icons.lock_person_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _errorMessage != null
                  ? AuthInlineFeedback(
                      key: const ValueKey('error'),
                      icon: Icons.error_outline_rounded,
                      color: AppColors.danger,
                      message: _errorMessage!,
                    )
                  : _successMessage != null
                  ? AuthInlineFeedback(
                      key: const ValueKey('success'),
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                      message: _successMessage!,
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _canSubmit ? _submit : null,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text(_isLoading ? 'Salvando...' : 'Redefinir senha'),
        ),
      ],
    );
  }
}
