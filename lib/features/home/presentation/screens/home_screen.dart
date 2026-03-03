import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tenniscourtcare/presentation/providers/dashboard_providers.dart';
import 'package:tenniscourtcare/presentation/providers/terrain_provider.dart';
import 'package:tenniscourtcare/presentation/providers/stock_provider.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/dashboard_header.dart';
import '../widgets/stats_carousel.dart';
import '../widgets/weather_card.dart';
import '../widgets/upcoming_events.dart';
import '../widgets/stock_alert_card.dart';
import '../widgets/court_list_sliver.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Providers
    final todayMaintenanceCount = ref.watch(todayMaintenanceCountProvider);
    final terrainsAsync = ref.watch(terrainsProvider);

    // New Stock Provider Logic
    final lowStockCount = ref.watch(lowStockCountProvider);
    // Convert List<StockItem> to int for the carousel
    final stockAlertCountAsync = ref.watch(stockItemsProvider).whenData((_) => lowStockCount);

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
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: WeatherCard(),
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
                  TextButton(
                    onPressed: () {
                      context.push('/add-terrain');
                    },
                    child: Text(
                      'Manage',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF003580),
                      ),
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
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: () {
            context.push('/maintenance');
          },
          backgroundColor: const Color(0xFF003580),
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
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
                  // Schedule - placeholder
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
