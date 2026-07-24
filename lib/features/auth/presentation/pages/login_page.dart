import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../domain/entities/auth_session.dart';
import '../state/app_session_controller.dart';
import '../state/login_controller.dart';
import '../widgets/auth_shell.dart';
import '../widgets/login_form.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthShell(
      title: 'Entrar no Faixa Amarela',
      subtitle: 'Escolha seu perfil para continuar.',
      showBack: false,
      child: LoginForm(onSubmit: () async => _handleLogin(context, ref)),
    );
  }

  Future<void> _handleLogin(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(loginControllerProvider.notifier).submit();
    if (!context.mounted || !ok) return;

    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) return;

    // O AppRouterGuard detecta a mudança de sessão e redireciona
    // automaticamente para /motorista ou /pais.
    //
    // O registro de push é feito aqui (fora do LoginController autoDispose)
    // para evitar StateError quando o provider é descartado pelo redirect.
    // É unawaited — não deve bloquear nem atrasar a navegação.
    unawaited(
      ref
          .read(pushRegistrationServiceProvider)
          .registerCurrentDevice(session.authorizationHeader),
    );

    // Apenas exibe erro se o perfil não é suportado pelo app.
    if (!session.user.isParent && !session.user.isDriverAppRole) {
      showAppSnackBar(
        context,
        message: 'Perfil não suportado: ${session.user.roles.join(', ')}',
        type: AppFeedbackType.error,
      );
      return;
    }

    // Fallback seguro: caso o AppRouterGuard + refreshListenable não consiga
    // completar o redirecionamento (condição de corrida), garantimos a navegação
    // para a home correta no próximo frame, mas apenas se ainda estivermos na
    // tela de login. Isso evita competir com o guard quando ele funciona.
    _safeGoHome(context, session);
  }

  void _safeGoHome(BuildContext context, AuthSession session) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      // Se o contexto já saiu da árvore do GoRouter (redirect do guard
      // removeu a LoginPage), não fazemos nada — a navegação já ocorreu.
      final String location;
      try {
        location = GoRouterState.of(context).matchedLocation;
      } catch (_) {
        return;
      }
      if (location != AppRoutes.login) return;

      if (!session.user.isActivated) {
        context.go(AppRoutes.activation);
        return;
      }

      if (session.user.isParent) {
        context.go(AppRoutes.parentHome);
      } else if (session.user.isDriverAppRole) {
        context.go(AppRoutes.driverHome);
      }
    });
  }
}
