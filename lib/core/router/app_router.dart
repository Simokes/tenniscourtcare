import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/admin/admin_dashboard_page.dart';
import '../../presentation/pages/error/access_denied_page.dart';
import '../../presentation/screens/home_screen.dart'; // Existing screen
import '../../domain/enums/role.dart';
import 'go_router_refresh_stream.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authStateProvider.notifier);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authNotifier.stream),
    redirect: (context, state) {
      // Note: ref.read(authStateProvider) gives the current state at the time of redirect call
      // Because we use refreshListenable, this callback is re-run on state change.
      final authState = ref.read(authStateProvider);

      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.uri.path == '/login';

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      // If logged in and trying to go to login, redirect to home/admin
      if (isLoggingIn) {
        final role = authState.value!.role;
        if (role == Role.admin) return '/admin';
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
      ),
    ],
  );
});
