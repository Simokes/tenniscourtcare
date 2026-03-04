import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/presentation/providers/auth_providers.dart';
import 'package:tenniscourtcare/presentation/providers/terrain_provider.dart';
import 'package:tenniscourtcare/presentation/providers/setup_providers.dart';
import 'package:tenniscourtcare/domain/models/setup_status.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/signup_page.dart';
import '../../presentation/pages/auth/admin_setup_page.dart';
import '../../presentation/pages/admin/admin_dashboard_page.dart';
import '../../presentation/pages/admin/pending_users_page.dart';
import '../../presentation/pages/error/access_denied_page.dart';
import 'package:tenniscourtcare/features/home/presentation/screens/home_screen.dart';
import 'package:tenniscourtcare/features/inventory/presentation/screens/stock_history_screen.dart';
import '../../features/inventory/presentation/screens/stock_screen.dart';
import '../../features/weather/presentation/screens/weather_screen.dart';
import '../../presentation/screens/calendar/calendar_screen.dart';
import '../../presentation/screens/maintenance_screen.dart';
import '../../presentation/screens/stats_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/add_terrain_screen.dart';
import '../../presentation/screens/terrain_maintenance_history_screen.dart';
import '../../domain/enums/role.dart';
import '../../domain/entities/terrain.dart';
import 'go_router_refresh_stream.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  // Watch the stream of setup status changes
  final setupStatusStream = ref.watch(setupStatusStreamProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      setupStatusStream.when(
        data: (status) => Stream.value(status),
        loading: () => Stream.value(SetupStatus.loading),
        error: (error, st) => Stream.value(SetupStatus.error),
      ),
    ),
    redirect: (context, state) {
      final setupStatusAsync = ref.read(setupStatusProvider);

      // If still loading or error, handle appropriately
      if (setupStatusAsync.isLoading && !setupStatusAsync.hasValue) return null;
      if (setupStatusAsync.hasError) return '/access-denied';

      final setupStatus = setupStatusAsync.value;
      if (setupStatus == null) return null;

      final isSettingUp = state.uri.path == '/admin-setup';
      final isLoggingIn = state.uri.path == '/login';
      final isSignup = state.uri.path == '/signup';
      final isAccessDenied = state.uri.path == '/access-denied';

      switch (setupStatus) {
        case SetupStatus.loading:
          return null;

        case SetupStatus.needsAdminSetup:
          if (!isSettingUp) return '/admin-setup';
          return null;

        case SetupStatus.needsLogin:
          if (!isLoggingIn && !isSignup) return '/login';
          return null;

        case SetupStatus.authenticated:
          if (isLoggingIn || isSettingUp || isSignup) {
            return '/';
          }
          return null;

        case SetupStatus.error:
          if (!isAccessDenied) return '/access-denied';
          return null;
      }
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
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
        path: '/admin/pending-users',
        builder: (context, state) => const PendingUsersPage(),
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
      GoRoute(path: '/stock', builder: (context, state) => const StockScreen()),
      GoRoute(
        path: '/weather/:type',
        builder: (context, state) {
          final typeStr = state.pathParameters['type'];
          final type = TerrainType.values.firstWhere(
            (e) => e.name == typeStr,
            orElse: () => TerrainType.terreBattue,
          );
          return WeatherScreen(titre: 'Météo du club', terrainType: type);
        },
      ),
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => const MaintenanceScreen(),
      ),
      GoRoute(path: '/stats', builder: (context, state) => const StatsScreen()),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
       GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/add-terrain',
        builder: (context, state) => const AddTerrainScreen(),
      ),
      GoRoute(
        path: '/terrain/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final terrains = ref.read(terrainsProvider).valueOrNull ?? [];
          try {
            final terrain = terrains.firstWhere((t) => t.id == id);
            return TerrainMaintenanceHistoryScreen(terrain: terrain);
          } catch (e) {
            return const AccessDeniedPage();
          }
        },
      ),
    ],
  );
});
