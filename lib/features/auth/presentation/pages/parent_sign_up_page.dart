import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_shell.dart';

class ParentSignUpPage extends ConsumerStatefulWidget {
  const ParentSignUpPage({super.key});

  @override
  ConsumerState<ParentSignUpPage> createState() => _ParentSignUpPageState();
}

class _ParentSignUpPageState extends ConsumerState<ParentSignUpPage> {
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
  bool _acceptedTerms = false;
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
    return AuthShell(
      title: 'Criar conta de responsável',
      subtitle:
          'Cadastre-se no app Faixa Amarela para gerenciar seus dependentes, fotos e acompanhar o transporte.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AuthTextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              labelText: 'Nome completo',
              prefixIcon: Icons.person_outline_rounded,
              validator: (value) =>
                  Validators.requiredField(value ?? '', fieldName: 'Nome'),
            ),
            const SizedBox(height: AppSpacing.md),
            _AuthTextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              labelText: 'E-mail',
              prefixIcon: Icons.mail_outline_rounded,
              validator: (value) => Validators.email(value ?? ''),
            ),
            const SizedBox(height: AppSpacing.md),
            _AuthTextFormField(
              controller: _cpfController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              inputFormatters: [InputFormatters.cpf()],
              labelText: 'CPF',
              hintText: '000.000.000-00',
              prefixIcon: Icons.badge_rounded,
              validator: (value) => Validators.cpf(value ?? ''),
            ),
            const SizedBox(height: AppSpacing.md),
            _AuthTextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              inputFormatters: [InputFormatters.phone()],
              labelText: 'Telefone / WhatsApp',
              hintText: '(00) 00000-0000',
              prefixIcon: Icons.phone_rounded,
              validator: (value) => Validators.phone(value ?? ''),
            ),
            const SizedBox(height: AppSpacing.md),
            _AuthTextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              labelText: 'Senha',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                onPressed: _isLoading
                    ? null
                    : () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppColors.ink.withValues(alpha: 0.45),
                  size: 22,
                ),
              ),
              validator: (value) => Validators.password(value ?? ''),
            ),
            const SizedBox(height: AppSpacing.md),
            _AuthTextFormField(
              controller: _passwordConfirmController,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              onFieldSubmitted: (_) => _submit(),
              labelText: 'Confirmar senha',
              prefixIcon: Icons.lock_reset_rounded,
              suffixIcon: IconButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() => _obscureConfirm = !_obscureConfirm),
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppColors.ink.withValues(alpha: 0.45),
                  size: 22,
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
            const SizedBox(height: AppSpacing.md),
            _TermsCheckbox(
              value: _acceptedTerms,
              enabled: !_isLoading,
              onChanged: (value) =>
                  setState(() => _acceptedTerms = value ?? false),
              onOpenTerms: _showTermsSheet,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              FaixaErrorBanner(message: _errorMessage!),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
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
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.ink,
                      ),
                    )
                  : const Text('Criar conta'),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.yellowLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.yellow.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                'Após o cadastro, verifique seu e-mail para ativar a conta. Depois disso, cadastre seus dependentes e aguarde o vínculo com o motorista pelo CPF.',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.75),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: _isLoading ? null : () => context.go(AppRoutes.login),
              icon: Icon(
                Icons.login_rounded,
                color: AppColors.ink.withValues(alpha: 0.55),
                size: 20,
              ),
              label: const Text('Já tenho conta'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.ink.withValues(alpha: 0.7),
                minimumSize: const Size.fromHeight(44),
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    if (!_acceptedTerms) {
      const msg = 'É necessário aceitar os termos de uso e privacidade.';
      setState(() => _errorMessage = msg);
      showAppSnackBar(context, message: msg, type: AppFeedbackType.warning);
      return;
    }

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
            acceptTerms: _acceptedTerms,
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
    } catch (_) {
      if (!mounted) return;
      const msg = 'Não foi possível criar sua conta agora. Tente novamente.';
      setState(() => _errorMessage = msg);
      showAppSnackBar(context, message: msg, type: AppFeedbackType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTermsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _TermsSheet(),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onOpenTerms,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onOpenTerms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(value: value, onChanged: enabled ? onChanged : null),
        Expanded(
          child: GestureDetector(
            onTap: onOpenTerms,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text.rich(
                TextSpan(
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'Li e aceito os '),
                    TextSpan(
                      text: 'Termos de Uso e Privacidade',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.yellowDark,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(
                      text:
                          ' (LGPD). Toque para saber como tratamos seus dados.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Texto acessível dos Termos de Uso e Privacidade (LGPD), exibido em
/// bottom sheet a partir do checkbox de aceite no cadastro do responsável.
class _TermsSheet extends StatelessWidget {
  const _TermsSheet();

  static const _sections = <(String, String)>[
    (
      'Dados que coletamos',
      'Do responsável: nome completo, CPF, e-mail e telefone. '
          'Dos dependentes: nome, CPF, escola, turno, endereço(s) e foto.',
    ),
    (
      'Quem vê o quê',
      'O motorista vê apenas os dados mínimos da criança (nome, escola, turno '
          'e endereço) e somente após o vínculo ser aceito pelo responsável. '
          'A equipe operacional (admin) acessa os dados estritamente para '
          'operar o serviço de transporte.',
    ),
    (
      'Uso da localização',
      'A localização da VAN é rastreada em tempo real apenas durante as rotas '
          'e é compartilhada com o responsável para acompanhamento do trajeto. '
          'Não rastreamos a localização do responsável nem da criança.',
    ),
    (
      'Retenção e exclusão',
      'Os dados são mantidos enquanto a conta estiver ativa e pelo período '
          'exigido por obrigações legais. Você pode solicitar a exclusão da '
          'conta e dos dados pessoais a qualquer momento.',
    ),
    (
      'Controlador e contato',
      'O controlador dos dados é a operadora do Faixa Amarela. Para exercer '
          'seus direitos (acesso, correção, portabilidade ou exclusão), use o '
          'canal de suporte disponível no aplicativo.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            Text(
              'Termos de Uso e Privacidade',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Resumo de como tratamos dados pessoais, em linguagem simples, '
              'nos termos da Lei Geral de Proteção de Dados (LGPD).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.slate,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final (title, body) in _sections) ...[
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.slate,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ],
        );
      },
    );
  }
}

class _AuthTextFormField extends StatelessWidget {
  const _AuthTextFormField({
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.obscureText = false,
    this.inputFormatters,
    required this.labelText,
    this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final String labelText;
  final String? hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      enabled: enabled,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      onFieldSubmitted: onFieldSubmitted,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: AppColors.ink,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.ink.withValues(alpha: 0.55),
        ),
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.ink.withValues(alpha: 0.4),
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: AppColors.ink.withValues(alpha: 0.4),
          size: 22,
        ),
        suffixIcon: suffixIcon,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
      ),
      validator: validator,
    );
  }
}
