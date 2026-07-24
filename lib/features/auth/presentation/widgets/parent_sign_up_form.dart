import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/app_error_reporter.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../core/utils/input_formatters.dart';
import 'auth_shell.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';

class ParentSignUpForm extends ConsumerStatefulWidget {
  const ParentSignUpForm({super.key});

  @override
  ConsumerState<ParentSignUpForm> createState() => _ParentSignUpFormState();
}

class _ParentSignUpFormState extends ConsumerState<ParentSignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            enabled: !_isLoading,
            decoration: const InputDecoration(
              labelText: 'Nome completo',
              prefixIcon: Icon(Icons.person_rounded),
            ),
            validator: (value) =>
                Validators.requiredField(value ?? '', fieldName: 'Nome'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !_isLoading,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.mail_rounded),
            ),
            validator: (value) => Validators.email(value ?? ''),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _cpfController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            enabled: !_isLoading,
            inputFormatters: [InputFormatters.cpf()],
            decoration: const InputDecoration(
              labelText: 'CPF',
              hintText: '000.000.000-00',
              prefixIcon: Icon(Icons.badge_rounded),
            ),
            validator: (value) => Validators.cpf(value ?? ''),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            enabled: !_isLoading,
            inputFormatters: [InputFormatters.phone()],
            decoration: const InputDecoration(
              labelText: 'Telefone / WhatsApp',
              hintText: '(00) 00000-0000',
              prefixIcon: Icon(Icons.phone_rounded),
            ),
            validator: (value) => Validators.phone(value ?? ''),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                onPressed: _isLoading
                    ? null
                    : () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
            ),
            validator: (value) => Validators.password(value ?? ''),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _passwordConfirmController,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            enabled: !_isLoading,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Confirmar senha',
              prefixIcon: const Icon(Icons.lock_reset_rounded),
              suffixIcon: IconButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() => _obscureConfirm = !_obscureConfirm),
                tooltip: _obscureConfirm ? 'Mostrar senha' : 'Ocultar senha',
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
            ),
            validator: (value) {
              final password = _passwordController.text;
              if ((value ?? '').trim().isEmpty) {
                return 'Confirme a senha.';
              }
              if (value != password) {
                return 'A confirmação de senha não confere.';
              }
              return null;
            },
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            AuthInlineFeedback(
              icon: Icons.error_outline_rounded,
              color: AppColors.danger,
              message: _errorMessage!,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _isLoading ? null : _submit,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_alt_1_rounded),
            label: Text(_isLoading ? 'Criando conta...' : 'Criar conta'),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Após o cadastro, verifique seu e-mail para ativar a conta. Depois disso, cadastre seus dependentes e aguarde o vínculo com o motorista pelo CPF.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.slate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: _isLoading ? null : () => context.go(AppRoutes.login),
            icon: const Icon(Icons.login_rounded),
            label: const Text('Já tenho conta'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .signUpParent(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            cpf: _cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
            cellPhone: _phoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
            password: _passwordController.text,
            passwordConfirmation: _passwordConfirmController.text,
          );

      if (!mounted) return;

      showAppSnackBar(
        context,
        message:
            'Conta criada! Verifique seu e-mail para ativar sua conta antes de entrar.',
        type: AppFeedbackType.success,
      );
      context.go(AppRoutes.login);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
      showAppSnackBar(context, message: e.message, type: AppFeedbackType.error);
    } catch (e) {
      if (!mounted) return;
      final msg = AppErrorReporter.messageFor(e);
      setState(() => _errorMessage = msg);
      showAppSnackBar(context, message: msg, type: AppFeedbackType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
