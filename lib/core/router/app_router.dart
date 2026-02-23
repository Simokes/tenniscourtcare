import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/admin_setup_page.dart';
import '../../presentation/pages/admin/admin_dashboard_page.dart';
import '../../presentation/pages/error/access_denied_page.dart';
import '../../presentation/screens/home_screen.dart'; // Existing screen
import '../../presentation/screens/stock_history_screen.dart';
import '../../domain/enums/role.dart';
import 'go_router_refresh_stream.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authStateProvider.notifier);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authNotifier.stream),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);

      final authStateValue = authState.value;

      final isSetupRequired = authStateValue?.isSetupRequired ?? false;
      final isLoggedIn = authStateValue?.user != null;

      final isSettingUp = state.uri.path == '/admin-setup';
      final isLoggingIn = state.uri.path == '/login';

      // 1. Redirection forcée vers le setup si aucun utilisateur n'existe
      if (isSetupRequired) {
        return isSettingUp ? null : '/admin-setup';
      }

      // 2. Empêcher l'accès à la page de setup si elle n'est pas requise
      if (isSettingUp) {
        return '/login';
      }

      // 3. Redirection vers login si non connecté
      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      // 4. Si connecté et tente d'accéder au login -> redirection vers dashboard
      if (isLoggingIn) {
        // final role = authStateValue!.user!.role;
        // L'admin utilise l'application normalement (comme un agent)
        // if (role == Role.admin) return '/admin';
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/admin-setup',
        builder: (context, state) => const AdminSetupPage(),
      ),
      GoRoute(
        path: '/access-denied',
        builder: (context, state) => const AccessDeniedPage(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardPage(),
        redirect: (context, state) {
          final user = ref.read(currentUserProvider);
          if (user?.role != Role.admin) return '/access-denied';
          return null;
        },
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
           GoRoute(
            path: 'stock-history',
            builder: (context, state) => const StockHistoryScreen(),
          ),
        ],
      ),
    ],
  );
});
