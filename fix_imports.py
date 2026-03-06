import re

def fix(filename, fixes):
    with open(filename, 'r') as f:
        content = f.read()
    for o, n in fixes:
        content = content.replace(o, n)
    with open(filename, 'w') as f:
        f.write(content)

fix('lib/features/home/presentation/screens/home_screen.dart', [
    ("../../maintenance/presentation/widgets/add_maintenance_sheet.dart", "../../../maintenance/presentation/widgets/add_maintenance_sheet.dart"),
    ("../../calendar/presentation/screens/add_edit_event_screen.dart", "../../../calendar/presentation/screens/add_edit_event_screen.dart")
])

fix('lib/features/home/presentation/widgets/court_list_sliver.dart', [
    ("../../maintenance/presentation/widgets/add_maintenance_sheet.dart", "../../../maintenance/presentation/widgets/add_maintenance_sheet.dart"),
    ("../providers/dashboard_providers.dart", "../../providers/dashboard_providers.dart")
])

fix('lib/features/home/presentation/widgets/upcoming_events_list.dart', [
    ("../providers/dashboard_providers.dart", "../../providers/dashboard_providers.dart")
])
