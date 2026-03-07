import 'package:tenniscourtcare/features/weather/providers/weather_for_club_provider.dart';

import 'package:tenniscourtcare/domain/enums/permission.dart';
import 'package:tenniscourtcare/domain/logic/permission_resolver.dart';
import 'package:tenniscourtcare/features/auth/providers/auth_providers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tenniscourtcare/features/terrain/providers/terrain_provider.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/dashboard_header.dart';
import '../widgets/stats_carousel.dart';
import 'package:tenniscourtcare/features/weather/presentation/widgets/weather_card.dart';
import '../widgets/upcoming_events_list.dart';
import '../widgets/current_events_banner.dart';
import '../widgets/day_timeline.dart';
import '../widgets/stock_alert_card.dart';
import '../widgets/court_list_sliver.dart';
import '../../../../shared/widgets/common/offline_warning_banner.dart';
import 'package:tenniscourtcare/features/maintenance/providers/maintenance_provider.dart';
import 'package:tenniscourtcare/features/maintenance/providers/maintenance_scheduler_provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../../maintenance/presentation/widgets/add_maintenance_sheet.dart';
import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  final _courtsKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dc = Theme.of(context).extension<DashboardColors>()!;

    // 1. Lire le rôle courant
    final user = ref.watch(currentUserProvider);
    final userRole = user?.role;
    final canEditMaintenance = userRole != null &&
        PermissionResolver.hasPermission(userRole, Permission.canEditMaintenance);
    final canManageReservations = userRole != null &&
        PermissionResolver.hasPermission(userRole, Permission.canManageReservations);

    // 2. Construire la liste conditionnellement
    final speedDialChildren = <SpeedDialChild>[
      if (canEditMaintenance)
        SpeedDialChild(
          child: const Icon(Icons.build_outlined, color: Colors.white),
          backgroundColor: dc.warningColor,
          label: 'Nouvelle maintenance',
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AddMaintenanceSheet(),
            );
          },
        ),
      if (canManageReservations)
        SpeedDialChild(
          child: const Icon(Icons.event_outlined, color: Colors.white),
          backgroundColor: dc.maintenanceColor,
          label: 'Nouvel événement',
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () {
            context.push('/add-edit-event');
          },
        ),
      if (canEditMaintenance)
        SpeedDialChild(
          child: const Icon(Icons.warning_amber_outlined, color: Colors.white),
          backgroundColor: dc.dangerColor,
          label: 'Signaler problème',
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AddMaintenanceSheet(urgentMode: true),
            );
          },
        ),
    ];

    // Activer le scheduler en gardant le timer actif tant que cet écran est affiché
    ref.watch(maintenanceSchedulerProvider);

    // Providers
    final terrainsAsync = ref.watch(terrainsProvider);
    final terrains = terrainsAsync.valueOrNull ?? const <Terrain>[];
    final TerrainType? terrainType = terrains.isNotEmpty
        ? terrains.first.type
        : null;
    final weatherAsync = terrainType != null
        ? ref.watch(weatherForClubProvider(terrainType))
        : const AsyncValue.loading();

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 1. Sticky Header
          const DashboardHeader(),

          // 1.4 Offline Warning Banner
          const SliverToBoxAdapter(
            child: OfflineWarningBanner(),
          ),

          // 1.5 Overdue Maintenance Alert
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, child) {
                final overdueCount = ref.watch(overdueCountProvider);
                if (overdueCount == 0) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: InkWell(
                    onTap: () => context.push('/maintenance'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: dc.dangerBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: dc.dangerColor.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: dc.dangerColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '⚠️ $overdueCount maintenance(s) en retard',
                              style: TextStyle(
                                color: dc.dangerColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right, color: dc.dangerColor),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 1.6 Current Events Banner
          const SliverToBoxAdapter(
            child: CurrentEventsBanner(),
          ),

          // 1.7 Day Timeline
          const SliverToBoxAdapter(
            child: DayTimeline(),
          ),

          // 2. Stats Carousel
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: StatsCarousel(),
            ),
          ),
          // 3. Court Availability Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    key: _courtsKey,
                    'Disponibilité des courts',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Court List (Sliver)
          const CourtListSliver(),

          // 5. Weather Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: weatherAsync.when(
                data: (weatherData) => WeatherCard(
                  weather: weatherData?.context.snapshot,
                  precip24h: weatherData?.context.precipitationLast24h, // ✅
                  frozen: weatherData?.frozen, // ✅
                  unplayable: weatherData?.unplayable, // ✅
                  onRefresh: () =>
                      ref.refresh(weatherForClubProvider(terrainType!)),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => const Center(child: Text('Erreur météo')),
              ),
            ),
          ),

          // 6. Upcoming Events
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: UpcomingEventsList(),
            ),
          ),

          // 7. Stock Alert (Conditional)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: StockAlertCard(),
            ),
          ),











        ],
      ),
      floatingActionButton: speedDialChildren.isEmpty
          ? null
          : SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        activeBackgroundColor: dc.dangerColor,
        activeForegroundColor: Colors.white,
        elevation: 8.0,
        shape: const CircleBorder(),
        children: speedDialChildren,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  Icons.dashboard_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  // Already on Home
                },
              ),
              IconButton(
                icon: Icon(Icons.stadium_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
                onPressed: () {
                  if (_courtsKey.currentContext != null) {
                    Scrollable.ensureVisible(
                      _courtsKey.currentContext!,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      alignment: 0.0,
                    );
                  }
                },
              ),
              const SizedBox(width: 40), // Spacer for FAB
              IconButton(
                icon: Icon(
                  Icons.calendar_today_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  context.push('/calendar'); // ✅ navigation calendar
                },
              ),
              IconButton(
                icon: Icon(Icons.settings_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
                onPressed: () {
                  context.push('/settings');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
