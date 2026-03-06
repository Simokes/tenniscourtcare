import 'package:tenniscourtcare/features/weather/providers/weather_for_club_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tenniscourtcare/features/home/providers/dashboard_providers.dart';
import 'package:tenniscourtcare/features/terrain/providers/terrain_provider.dart';
import 'package:tenniscourtcare/features/inventory/providers/stock_provider.dart';
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
import 'package:tenniscourtcare/features/maintenance/providers/maintenance_provider.dart';
import 'package:tenniscourtcare/features/maintenance/providers/maintenance_scheduler_provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../../maintenance/presentation/widgets/add_maintenance_sheet.dart';
import '../../../calendar/presentation/screens/add_edit_event_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activer le scheduler en gardant le timer actif tant que cet écran est affiché
    ref.watch(maintenanceSchedulerProvider);

    // Providers
    final todayMaintenanceCount = ref.watch(todayMaintenanceCountProvider);
    final terrainsAsync = ref.watch(terrainsProvider);
    final terrains = terrainsAsync.valueOrNull ?? const <Terrain>[];
    final TerrainType? terrainType = terrains.isNotEmpty
        ? terrains.first.type
        : null;
    final weatherAsync = terrainType != null
        ? ref.watch(weatherForClubProvider(terrainType))
        : const AsyncValue.loading();

    // New Stock Provider Logic
    final lowStockCount = ref.watch(lowStockCountProvider);
    // Convert List<StockItem> to int for the carousel
    final stockAlertCountAsync = ref
        .watch(stockItemsProvider)
        .whenData((_) => lowStockCount);

    // Calculate operational courts for the stats card
    final operationalCountAsync = terrainsAsync.whenData(
      (terrains) =>
          terrains.where((t) => t.status == TerrainStatus.playable).toList(),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // 1. Sticky Header
          const DashboardHeader(),

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
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '⚠️ $overdueCount maintenance(s) en retard',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.red),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: StatsCarousel(
                todayMaintenanceCount: todayMaintenanceCount,
                stockAlertCount: stockAlertCountAsync,
                operationalTerrainsCount: operationalCountAsync,
              ),
            ),
          ),

          // 3. Weather Card
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

          // 4. Upcoming Events
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: UpcomingEventsList(),
            ),
          ),

          // 5. Stock Alert (Conditional)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: StockAlertCard(),
            ),
          ),

          // 6. Court Availability Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Court Availability',
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

          // 7. Court List (Sliver)
          const CourtListSliver(),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: const Color(0xFF003580),
        foregroundColor: Colors.white,
        activeBackgroundColor: Colors.red,
        activeForegroundColor: Colors.white,
        elevation: 8.0,
        shape: const CircleBorder(),
        children: [
          SpeedDialChild(
            child: const Icon(Icons.build_outlined, color: Colors.white),
            backgroundColor: Colors.orange,
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
          SpeedDialChild(
            child: const Icon(Icons.event_outlined, color: Colors.white),
            backgroundColor: Colors.blue,
            label: 'Nouvel événement',
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditEventScreen(),
                ),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.warning_amber_outlined, color: Colors.white),
            backgroundColor: Colors.red,
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
        ],
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
                icon: const Icon(
                  Icons.dashboard_rounded,
                  color: Color(0xFF003580),
                ),
                onPressed: () {
                  // Already on Home
                },
              ),
              IconButton(
                icon: Icon(Icons.stadium_rounded, color: Colors.grey.shade400),
                onPressed: () {
                  // Scroll to Courts? Or navigate? For now placeholder
                },
              ),
              const SizedBox(width: 40), // Spacer for FAB
              IconButton(
                icon: Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.grey.shade400,
                ),
                onPressed: () {
                  context.push('/calendar'); // ✅ navigation calendar
                },
              ),
              IconButton(
                icon: Icon(Icons.settings_rounded, color: Colors.grey.shade400),
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
