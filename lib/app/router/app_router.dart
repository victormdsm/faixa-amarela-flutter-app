import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/finalize_registration_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/parent_sign_up_page.dart';
import '../../features/driver_portal/presentation/pages/driver_add_client_page.dart';
import '../../features/driver_portal/presentation/pages/driver_clients_page.dart';
import '../../features/driver_portal/presentation/pages/driver_dashboard_page.dart';
import '../../features/driver_portal/presentation/pages/driver_routes_page.dart';
import '../../features/driver_portal/presentation/pages/driver_settings_page.dart';
import '../../features/driver_portal/presentation/pages/driver_shell_page.dart';
import '../../features/parent_portal/presentation/pages/parent_boardings_page.dart';
import '../../features/parent_portal/presentation/pages/parent_children_page.dart';
import '../../features/parent_portal/presentation/pages/parent_dashboard_page.dart';
import '../../features/parent_portal/presentation/pages/parent_routes_page.dart';
import '../../features/parent_portal/presentation/pages/parent_shell_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/transport_search/presentation/pages/search_transport_page.dart';

// ---------------------------------------------------------------------------
// Route path constants
// ---------------------------------------------------------------------------
class AppRoutes {
  AppRoutes._();

  // Auth
  static const login = '/';
  static const forgotPassword = '/forgot-password';
  static const parentSignUp = '/parent-sign-up';
  static const finalizeRegistration = '/finalize-registration';
  static const searchTransport = '/search-transport';

  // Driver portal
  static const driverHome = '/motorista';
  static const driverClients = '/motorista/clientes';
  static const driverAddClient = '/motorista/clientes/adicionar';
  static const driverRoutes = '/motorista/rotas';
  static const driverProfile = '/motorista/perfil';
  static const driverNotifications = '/motorista/notificacoes';

  // Driver push routes (open on top of shell)
  static const driverSettings = '/motorista/settings';

  // Parent portal
  static const parentHome = '/pais';
  static const parentChildren = '/pais/dependentes';
  static const parentRoutes = '/pais/rotas';
  static const parentBoardings = '/pais/embarques';
  static const parentNotifications = '/pais/notificacoes';
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    routes: [
      // ── Auth routes (no shell) ──────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.parentSignUp,
        builder: (context, state) => const ParentSignUpPage(),
      ),
      GoRoute(
        path: AppRoutes.finalizeRegistration,
        builder: (context, state) => const FinalizeRegistrationPage(),
      ),
      GoRoute(
        path: AppRoutes.searchTransport,
        builder: (context, state) => const SearchTransportPage(),
      ),

      // ── Driver portal (bottom navigation shell) ────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DriverShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.driverHome,
                builder: (context, state) => const DriverDashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.driverClients,
                builder: (context, state) => const DriverClientsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.driverRoutes,
                builder: (context, state) => const DriverRoutesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.driverProfile,
                builder: (context, state) => const DriverSettingsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.driverNotifications,
                builder: (context, state) => const NotificationsPage(),
              ),
            ],
          ),
        ],
      ),

      // Driver push routes (displayed on top of the shell)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.driverSettings,
        builder: (context, state) => const DriverSettingsPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.driverAddClient,
        builder: (context, state) => const DriverAddClientPage(),
      ),

      // ── Parent portal (bottom navigation shell) ────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ParentShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.parentHome,
                builder: (context, state) => const ParentDashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.parentChildren,
                builder: (context, state) => const ParentChildrenPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.parentRoutes,
                builder: (context, state) => const ParentRoutesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.parentBoardings,
                builder: (context, state) => const ParentBoardingsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.parentNotifications,
                builder: (context, state) => const NotificationsPage(),
              ),
            ],
          ),
        ],
      ),
    ],

    // ── Error page ──────────────────────────────────────────────────
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rota nao encontrada')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Nao foi possivel abrir "${state.uri}".',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    },
  );
});
