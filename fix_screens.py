with open("lib/features/home/presentation/screens/home_screen.dart", "r") as f:
    content = f.read()

import re

if "CurrentEventsBanner" not in content:
    content = content.replace(
        "import '../widgets/upcoming_events.dart';",
        "import '../widgets/upcoming_events_list.dart';\nimport '../widgets/current_events_banner.dart';\nimport '../widgets/day_timeline.dart';"
    )
    content = content.replace(
        "import 'package:tenniscourtcare/features/maintenance/providers/maintenance_scheduler_provider.dart';",
        "import 'package:tenniscourtcare/features/maintenance/providers/maintenance_scheduler_provider.dart';\nimport 'package:flutter_speed_dial/flutter_speed_dial.dart';\nimport '../../../features/maintenance/presentation/widgets/add_maintenance_sheet.dart';\nimport '../../../features/calendar/presentation/screens/add_edit_event_screen.dart';"
    )
    content = content.replace(
        "// 2. Stats Carousel",
        "// 1.6 Current Events Banner\n          const SliverToBoxAdapter(\n            child: CurrentEventsBanner(),\n          ),\n\n          // 1.7 Day Timeline\n          const SliverToBoxAdapter(\n            child: DayTimeline(),\n          ),\n\n          // 2. Stats Carousel"
    )

    # Replace FAB
    fab_match = re.search(r"floatingActionButton: SizedBox\(.*?floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,", content, re.DOTALL)

    if fab_match:
        content = content[:fab_match.start()] + """floatingActionButton: SpeedDial(
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,""" + content[fab_match.end():]

    with open("lib/features/home/presentation/screens/home_screen.dart", "w") as f:
        f.write(content)

with open("lib/features/home/presentation/widgets/court_list_sliver.dart", "r") as f:
    content = f.read()

if "CurrentEventsBanner" not in content: # actually if "todayPlannedMaintenancesProvider" not in content
    # I'll just use sed/patch since it's easier
    pass
