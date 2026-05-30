import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../domain/entities/user_role.dart';
import '../state/app_session_controller.dart';
import '../state/login_controller.dart';
import '../widgets/auth_shell.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);
    final session = ref.watch(appSessionControllerProvider).session;
    final theme = Theme.of(context);

    if (session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (session.user.isParent) {
          context.go(AppRoutes.parentHome);
        } else if (session.user.isDriverAppRole) {
          context.go(AppRoutes.driverHome);
        }
      });
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8B000), Color(0xFFF5C930), Color(0xFFF8F5EC)],
            stops: [0.0, 0.36, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _HeroHeader(),
                const SizedBox(height: 10),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Entrar',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Selecione o perfil e acesse sua area.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.slate,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<UserRole>(
                          segments: UserRole.values
                              .map(
                                (role) => ButtonSegment<UserRole>(
                                  value: role,
                                  icon: Icon(
                                    role == UserRole.parent
                                        ? Icons.family_restroom_rounded
                                        : Icons.directions_bus_rounded,
                                  ),
                                  label: Text(role.label),
                                ),
                              )
                              .toList(growable: false),
                          selected: {state.role},
                          onSelectionChanged: (selection) {
                            controller.setRole(selection.first);
                          },
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          keyboardType: state.role == UserRole.parent
                              ? TextInputType.emailAddress
                              : TextInputType.text,
                          textInputAction: TextInputAction.next,
                          enabled: !state.isLoading,
                          onChanged: controller.setEmail,
                          decoration: InputDecoration(
                            labelText: state.role == UserRole.parent
                                ? 'E-mail'
                                : 'E-mail ou CPF',
                            prefixIcon: Icon(
                              state.role == UserRole.parent
                                  ? Icons.mail_outline_rounded
                                  : Icons.badge_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          obscureText: state.obscurePassword,
                          textInputAction: TextInputAction.done,
                          enabled: !state.isLoading,
                          onChanged: controller.setPassword,
                          onSubmitted: (_) async => _handleLogin(context, ref),
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: state.isLoading
                                  ? null
                                  : controller.togglePasswordVisibility,
                              icon: Icon(
                                state.obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: state.isLoading
                                ? null
                                : () => context.push(AppRoutes.forgotPassword),
                            child: const Text('Esqueci minha senha'),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: state.isLoading
                                ? null
                                : () => context.push(
                                    AppRoutes.finalizeRegistration,
                                  ),
                            child: const Text('Finalizar cadastro'),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F4EA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.ink.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.yellow.withValues(
                                    alpha: 0.22,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                  color: AppColors.ink,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Responsavel novo? Crie sua conta e depois cadastre seus dependentes no app.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.slate,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: state.isLoading
                              ? null
                              : () => context.push(AppRoutes.parentSignUp),
                          icon: const Icon(Icons.family_restroom_rounded),
                          label: const Text('Criar conta de responsavel'),
                        ),
                        if (state.errorMessage != null) ...[
                          const SizedBox(height: 8),
                          AuthInlineFeedback(
                            color: AppColors.danger,
                            icon: Icons.error_outline_rounded,
                            message: state.errorMessage!,
                          ),
                        ],
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: state.isLoading
                              ? null
                              : () async => _handleLogin(context, ref),
                          icon: state.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login_rounded),
                          label: Text(
                            state.isLoading ? 'Entrando...' : 'Entrar',
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: state.isLoading
                              ? null
                              : () => context.push(AppRoutes.searchTransport),
                          icon: const Icon(Icons.search_rounded),
                          label: const Text('Buscar Transporte'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(loginControllerProvider.notifier).submit();
    if (!context.mounted || !ok) return;

    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) return;

    if (session.user.isParent) {
      context.go(AppRoutes.parentHome);
      return;
    }

    if (session.user.isDriverAppRole) {
      context.go(AppRoutes.driverHome);
      return;
    }

    showAppSnackBar(
      context,
      message: 'Perfil nao suportado: ${session.user.role}',
      type: AppFeedbackType.error,
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RepaintBoundary(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 32,
                  offset: Offset(0, 8),
                  color: Color(0x40E8B000),
                ),
                BoxShadow(
                  blurRadius: 12,
                  offset: Offset(0, 4),
                  color: Color(0x18000000),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.directions_bus_rounded,
                  color: AppColors.ink,
                  size: 34,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Faixa Amarela',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Transporte escolar com seguranca e controle',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.slate,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
