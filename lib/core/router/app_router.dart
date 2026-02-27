import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/providers/terrain_provider.dart';
import '../../presentation/providers/setup_providers.dart'; // ✅ Imports setupStatusStreamProvider
import '../../domain/models/setup_status.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/admin_setup_page.dart';
import '../../presentation/pages/admin/admin_dashboard_page.dart';
import '../../presentation/pages/error/access_denied_page.dart';
import 'package:tenniscourtcare/features/home/presentation/screens/home_screen.dart';
import 'package:tenniscourtcare/features/inventory/presentation/screens/stock_history_screen.dart';
import '../../features/inventory/presentation/screens/stock_screen.dart';
import '../../features/weather/presentation/screens/weather_screen.dart';
import '../../presentation/screens/maintenance_screen.dart';
import '../../presentation/screens/stats_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/add_terrain_screen.dart';
import '../../presentation/screens/terrain_maintenance_history_screen.dart';
import '../../domain/enums/role.dart';
import '../../domain/entities/terrain.dart';
import 'go_router_refresh_stream.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  // ✅ FIXED: Watch setupStatusStreamProvider (StreamProvider)
  // NOT setupStatusProvider (FutureProvider)
  final setupStatusStream = ref.watch(setupStatusStreamProvider);

  return GoRouter(
    initialLocation: '/',

    // ✅ Now setupStatusStream is a real Stream<SetupStatus>
    // GoRouterRefreshStream expects Stream<dynamic>
    refreshListenable: GoRouterRefreshStream(
      setupStatusStream.when(
        data: (status) => Stream.value(status),
        loading: () => Stream.value(SetupStatus.loading),
        error: (error, st) => Stream.value(SetupStatus.error),
      ),
    ),

    redirect: (context, state) {
      // ✅ Read the FutureProvider for redirect logic
      final setupStatusAsync = ref.read(setupStatusProvider);

      // If still loading, return null (don't redirect yet)
      if (setupStatusAsync.isLoading) return null;

      // If error, redirect to error page
      if (setupStatusAsync.hasError) return '/access-denied';

      final setupStatus = setupStatusAsync.value;
      if (setupStatus == null) return null;

      final isSettingUp = state.uri.path == '/admin-setup';
      final isLoggingIn = state.uri.path == '/login';

      switch (setupStatus) {
        case SetupStatus.loading:
          return null;

        case SetupStatus.needsAdminSetup:
          if (isSettingUp) return null;
          return '/admin-setup';

        case SetupStatus.needsLogin:
          if (isLoggingIn) return null;
          if (isSettingUp) return '/login';
          return '/login';

        case SetupStatus.authenticated:
          if (isLoggingIn || isSettingUp) {
            return '/';
          }
          return null;

        case SetupStatus.error:
          if (state.uri.path == '/access-denied') return null;
          return '/access-denied';
      }
    },

    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/admin-setup',
        builder: (context, state) => const AdminSetupPage(),
      ),
      GoRoute(
        path: '/access-denied',
        builder: (context, state) => const AccessDeniedPage(),
      ),
      // ✅ FIXED VERSION - SIMPLIFIÉ
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardPage(),
        redirect: (context, state) {
          // ✅ FIXED: currentUserProvider returns UserEntity? directly
          final user = ref.read(currentUserProvider);

          // Check if user is admin
          final isAdmin = user?.role == Role.admin;

          // If not admin, deny access
          if (!isAdmin) {
            return '/access-denied';
          }

          return null; // Allow access to /admin
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
        path: '/add-terrain',
        builder: (context, state) => const AddTerrainScreen(),
      ),
      GoRoute(
        path: '/terrain/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          // ✅ FIXED: Use const [] as safe fallback
          final terrains = ref.read(terrainsProvider).valueOrNull ?? const [];
          //                                                         ^^^^^^
          //                                               Use const (immutable)
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
