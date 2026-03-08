import 'package:tenniscourtcare/domain/enums/permission.dart';
import 'package:tenniscourtcare/domain/logic/permission_resolver.dart';
import 'package:tenniscourtcare/features/auth/providers/auth_providers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/dashboard_header_enriched.dart';
import '../widgets/alert_strip.dart';
import '../widgets/kpi_strip.dart';
import '../widgets/prochains_creneaux.dart';
import '../widgets/stock_alert_card.dart';
import '../widgets/court_list_sliver.dart';
import 'package:tenniscourtcare/features/maintenance/providers/maintenance_scheduler_provider.dart';
import '../../../maintenance/presentation/widgets/add_maintenance_sheet.dart';
import 'package:tenniscourtcare/features/home/providers/dashboard_providers.dart';

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
    final cs = Theme.of(context).colorScheme;

    // 1. Lire le rôle courant
    final user = ref.watch(currentUserProvider);
    final userRole = user?.role;
    final canEditMaintenance = userRole != null &&
        PermissionResolver.hasPermission(userRole, Permission.canEditMaintenance);
    final canManageReservations = userRole != null &&
        PermissionResolver.hasPermission(userRole, Permission.canManageReservations);

    FloatingActionButton? fab;
    if (user != null) {
      if (canEditMaintenance) {
        fab = FloatingActionButton.extended(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AddMaintenanceSheet(),
            );
          },
          label: const Text('Maintenance'),
          icon: const Icon(Icons.add),
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
        );
      } else if (canManageReservations) {
        fab = FloatingActionButton.extended(
          onPressed: () {
            context.push('/add-edit-event');
          },
          label: const Text('Événement'),
          icon: const Icon(Icons.add),
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
        );
      }
    }

    // Activer le scheduler en gardant le timer actif tant que cet écran est affiché
    ref.watch(maintenanceSchedulerProvider);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 1. Sticky Header Enriched
          const DashboardHeaderEnriched(),

          // 2. Alert Strip
          const SliverToBoxAdapter(
            child: AlertStrip(),
          ),

          // 3. KPI Strip
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: KpiStrip(),
            ),
          ),

          // 4. Current Events Bandeau
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, _) {
                final events = ref.watch(currentEventsProvider);
                if (events.isEmpty) return const SizedBox.shrink();
                final event = events.first;
                return Container(
                  height: 52,
                  color: Color(event.color).withValues(alpha: 0.85),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.radio_button_checked, size: 14, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'EN COURS  ${event.title}',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 5. Court Availability Header
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
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 6. Court List (Sliver)
          const CourtListSliver(),

          // 7. Prochains Creneaux
          const SliverToBoxAdapter(
            child: ProchainsCreneaux(),
          ),

          // 8. Stock Alert (Conditional)
          const SliverToBoxAdapter(
            child: StockAlertCard(),
          ),

          // 9. Bottom Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
      floatingActionButton: fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: cs.onSurface.withValues(alpha: 0.1),
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
