import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_router_guard.dart';
import '../../app/theme/app_theme.dart';
import '../../core/presentation/widgets/faixa_app_bar.dart';
import '../../domain/models/child.dart';
import '../../features/auth/presentation/pages/activation_page.dart';
import '../../features/auth/presentation/pages/finalize_registration_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/parent_sign_up_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/state/app_session_controller.dart';
import '../../features/driver_portal/presentation/pages/driver_add_client_page.dart';
import '../../features/driver_portal/presentation/pages/driver_dashboard_page.dart';
import '../../features/driver_portal/presentation/pages/driver_enrollments_page.dart';
import '../../features/driver_portal/presentation/pages/driver_lookup_child_page.dart';
import '../../features/driver_portal/presentation/pages/driver_route_execution_page.dart';
import '../../features/driver_portal/presentation/pages/driver_routes_page.dart';
import '../../features/driver_portal/presentation/pages/driver_change_requests_page.dart';
import '../../features/driver_portal/presentation/pages/driver_settings_page.dart';
import '../../features/driver_portal/presentation/pages/driver_shell_page.dart';
import '../../features/parent_portal/presentation/pages/add_child_page.dart';
import '../../features/parent_portal/presentation/pages/child_detail_page.dart';
import '../../features/parent_portal/presentation/pages/parent_boardings_page.dart';
import '../../features/parent_portal/presentation/pages/parent_children_page.dart';
import '../../features/parent_portal/presentation/pages/parent_dashboard_page.dart';
import '../../features/parent_portal/presentation/pages/parent_enrollments_page.dart';
import '../../features/parent_portal/presentation/pages/parent_profile_page.dart';
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
  static const resetPassword = '/reset-password';
  static const parentSignUp = '/parent-sign-up';
  static const finalizeRegistration = '/finalize-registration';
  static const searchTransport = '/search-transport';
  static const activation = '/activation';

  // Driver portal
  static const driverHome = '/motorista';
  static const driverClients = '/motorista/clientes';
  static const driverAddClient = '/motorista/clientes/adicionar';
  static const driverRoutes = '/motorista/rotas';
  static const driverNotifications = '/motorista/notificacoes';
  static const driverRouteExecution = '/motorista/rota';
  static const driverEnrollments = '/motorista/enrollments';

  // Driver push routes (open on top of shell)
  static const driverSettings = '/motorista/settings';
  static const driverChangeRequests = '/motorista/solicitacoes';

  // Parent portal
  static const parentHome = '/pais';
  static const parentChildren = '/pais/dependentes';
  static const parentChildrenAdd = '/pais/dependentes/adicionar';
  static const parentChildDetail = '/pais/dependentes/detalhes';
  static const parentRoutes = '/pais/rotas';
  static const parentBoardings = '/pais/embarques';
  static const parentEnrollments = '/pais/enrollments';
  static const parentProfile = '/pais/perfil';
  static const parentNotifications = '/pais/notificacoes';
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ValueNotifier<int>(0);

  ref.listen(appSessionControllerProvider, (previous, next) {
    refreshNotifier.value++;
  });

  String? redirectLogic(BuildContext context, GoRouterState state) {
    // uri.path é mais confiável que matchedLocation durante inicialização.
    final location = state.uri.path.isEmpty ? '/' : state.uri.path;
    final sessionState = ref.read(appSessionControllerProvider);
    return AppRouterGuard.redirect(
      session: sessionState.session,
      isLoading: sessionState.isLoading,
      location: location,
      loginRole: sessionState.loginRole,
    );
  }

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    refreshListenable: refreshNotifier,
    redirect: redirectLogic,
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
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordPage(),
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
      GoRoute(
        path: AppRoutes.activation,
        builder: (context, state) => const ActivationPage(),
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
                builder: (context, state) => const DriverLookupChildPage(),
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
                path: AppRoutes.driverEnrollments,
                builder: (context, state) => const DriverEnrollmentsPage(),
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
        path: AppRoutes.driverChangeRequests,
        builder: (context, state) => const DriverChangeRequestsPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.driverAddClient,
        builder: (context, state) => const DriverAddClientPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.driverRouteExecution,
        builder: (context, state) => const DriverRouteExecutionPage(),
      ),

      // Parent push routes (displayed on top of the shell)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.parentChildrenAdd,
        builder: (context, state) =>
            AddChildPage(childToEdit: state.extra as Child?),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.parentChildDetail,
        builder: (context, state) =>
            ChildDetailPage(child: state.extra as Child),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.parentProfile,
        builder: (context, state) => const ParentProfilePage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.parentEnrollments,
        builder: (context, state) => const ParentEnrollmentsPage(),
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
      final theme = Theme.of(context);
      return Scaffold(
        backgroundColor: AppColors.surfaceSoft,
        appBar: FaixaAppBar.screen(title: 'Página não encontrada'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.warning,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Não foi possível abrir "${state.uri}".',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.ink,
                  ),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Detalhe: ${state.error}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
});
