import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/presentation/widgets/faixa_portal_home.dart';
import '../../../auth/presentation/state/app_session_controller.dart';

class ParentDashboardPage extends ConsumerWidget {
  const ParentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionControllerProvider).session;

    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.login);
      });
    }

    return FaixaPortalHome(
      userName: session?.user.name ?? 'Responsavel',
      roleLabel: 'Portal da familia',
      statusLabel: 'Acompanhe dependentes e rotas',
      statusActive: true,
      onLogout: () => ref.read(appSessionControllerProvider.notifier).clear(),
      metrics: const [
        PortalHomeMetric(
          label: 'Dependentes',
          value: '--',
          icon: Icons.child_care_rounded,
        ),
        PortalHomeMetric(
          label: 'Rotas',
          value: '--',
          icon: Icons.route_rounded,
        ),
      ],
      actions: [
        PortalHomeAction(
          label: 'Dependentes',
          icon: Icons.child_friendly_rounded,
          onTap: () => StatefulNavigationShell.of(context).goBranch(1),
        ),
        PortalHomeAction(
          label: 'Rotas',
          icon: Icons.alt_route_rounded,
          onTap: () => StatefulNavigationShell.of(context).goBranch(2),
        ),
        PortalHomeAction(
          label: 'Embarques',
          icon: Icons.hail_rounded,
          onTap: () => StatefulNavigationShell.of(context).goBranch(3),
        ),
        PortalHomeAction(
          label: 'Avisos',
          icon: Icons.notifications_rounded,
          onTap: () => StatefulNavigationShell.of(context).goBranch(4),
        ),
      ],
    );
  }
}
