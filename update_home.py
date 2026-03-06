import re

with open('lib/features/home/presentation/screens/home_screen.dart', 'r') as f:
    content = f.read()

# Add imports
imports_to_add = """
import 'package:tenniscourtcare/domain/enums/permission.dart';
import 'package:tenniscourtcare/domain/enums/role.dart';
import 'package:tenniscourtcare/domain/logic/permission_resolver.dart';
import 'package:tenniscourtcare/features/auth/providers/auth_providers.dart';
"""
if "import 'package:tenniscourtcare/domain/enums/permission.dart';" not in content:
    content = content.replace("import 'package:tenniscourtcare/features/weather/providers/weather_for_club_provider.dart';",
                              "import 'package:tenniscourtcare/features/weather/providers/weather_for_club_provider.dart';\n" + imports_to_add)

# Change ConsumerWidget to ConsumerStatefulWidget
content = content.replace('class HomeScreen extends ConsumerWidget {', 'class HomeScreen extends ConsumerStatefulWidget {')
content = content.replace('const HomeScreen({super.key});\n\n  @override\n  Widget build(BuildContext context, WidgetRef ref) {', '''const HomeScreen({super.key});

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
  Widget build(BuildContext context) {''')

# Update references to `ref` since we're in ConsumerState now
content = content.replace('Widget build(BuildContext context) {', 'Widget build(BuildContext context) {')
# wait, it's just `Widget build(BuildContext context)` in `ConsumerState`?
# In riverpod, `ConsumerState` has `ref` available as a property. So `Widget build(BuildContext context)` is correct, and we can just use `ref`.

# Add role logic
role_logic = """
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
      if (canManageReservations)
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
      if (canEditMaintenance)
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
    ];
"""
content = content.replace('// Activer le scheduler en gardant le timer actif tant que cet écran est affiché', role_logic + '\n    // Activer le scheduler en gardant le timer actif tant que cet écran est affiché')

# Update CustomScrollView
content = content.replace('CustomScrollView(', 'CustomScrollView(\n        controller: _scrollController,')

# Update Court Availability Header Key and Text
content = content.replace("Text(\n                    'Court Availability',", "Text(\n                    key: _courtsKey,\n                    'Disponibilité des courts',")

# Rearrange Slivers
# Currently, the order is:
# 1. Sticky Header
# 1.5 Overdue Maintenance Alert
# 1.6 Current Events Banner
# 1.7 Day Timeline
# 2. Stats Carousel
# 3. Weather Card
# 4. Upcoming Events
# 5. Stock Alert
# 6. Court Availability Header
# 7. Court List

# We want:
# 1. DashboardHeader
# 2. Overdue Maintenance Alert
# 3. Current Events Banner
# 4. Day Timeline
# 5. Stats Carousel
# 6. Court Availability Header  ← déplacé de la position 9 (wait, the prompt says 6. from 9. Actually it's currently 6 and 7 in the code)
# 7. CourtListSliver            ← déplacé de la position 10 (currently 7 in code)
# 8. Weather Card
# 9. Upcoming Events
# 10. Stock Alert Card

# Let's extract the slivers
import re

sliver_pattern = r'(// 3\. Weather Card.*?)(?=// 4\. Upcoming Events)'
weather_card_match = re.search(sliver_pattern, content, re.DOTALL)
weather_card = weather_card_match.group(1) if weather_card_match else ""

sliver_pattern = r'(// 4\. Upcoming Events.*?)(?=// 5\. Stock Alert \(Conditional\))'
upcoming_events_match = re.search(sliver_pattern, content, re.DOTALL)
upcoming_events = upcoming_events_match.group(1) if upcoming_events_match else ""

sliver_pattern = r'(// 5\. Stock Alert \(Conditional\).*?)(?=// 6\. Court Availability Header)'
stock_alert_match = re.search(sliver_pattern, content, re.DOTALL)
stock_alert = stock_alert_match.group(1) if stock_alert_match else ""

sliver_pattern = r'(// 6\. Court Availability Header.*?)(?=// 7\. Court List \(Sliver\))'
court_avail_match = re.search(sliver_pattern, content, re.DOTALL)
court_avail = court_avail_match.group(1) if court_avail_match else ""

sliver_pattern = r'(// 7\. Court List \(Sliver\).*?)(?=],\n      floatingActionButton)'
court_list_match = re.search(sliver_pattern, content, re.DOTALL)
court_list = court_list_match.group(1) if court_list_match else ""

if weather_card and upcoming_events and stock_alert and court_avail and court_list:
    # Remove these from content
    content = content.replace(weather_card, "")
    content = content.replace(upcoming_events, "")
    content = content.replace(stock_alert, "")
    content = content.replace(court_avail, "")
    content = content.replace(court_list, "")

    # Reinsert them in the correct order
    new_order = court_avail + court_list + weather_card + upcoming_events + stock_alert

    # Insert right before the closing bracket of slivers
    content = content.replace('          // 2. Stats Carousel\n          const SliverToBoxAdapter(\n            child: Padding(\n              padding: EdgeInsets.symmetric(vertical: 24),\n              child: StatsCarousel(),\n            ),\n          ),\n\n        ],',
    '          // 2. Stats Carousel\n          const SliverToBoxAdapter(\n            child: Padding(\n              padding: EdgeInsets.symmetric(vertical: 24),\n              child: StatsCarousel(),\n            ),\n          ),\n\n' + new_order + '        ],')


# Update SpeedDial
speed_dial_code = """      floatingActionButton: speedDialChildren.isEmpty
          ? null
          : SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: const Color(0xFF003580),
        foregroundColor: Colors.white,
        activeBackgroundColor: Colors.red,
        activeForegroundColor: Colors.white,
        elevation: 8.0,
        shape: const CircleBorder(),
        children: speedDialChildren,
      ),"""

# Let's replace the whole floatingActionButton part
content = re.sub(r'      floatingActionButton: SpeedDial\(.*?\),\n      floatingActionButtonLocation:', speed_dial_code + '\n      floatingActionButtonLocation:', content, flags=re.DOTALL)

# Update Bottom AppBar Stadium icon
old_stadium_icon = """              IconButton(
                icon: Icon(Icons.stadium_rounded, color: Colors.grey.shade400),
                onPressed: () {
                  // Scroll to Courts? Or navigate? For now placeholder
                },
              ),"""
new_stadium_icon = """              IconButton(
                icon: Icon(Icons.stadium_rounded, color: Colors.grey.shade400),
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
              ),"""
content = content.replace(old_stadium_icon, new_stadium_icon)

with open('lib/features/home/presentation/screens/home_screen.dart', 'w') as f:
    f.write(content)
