import re

# 1. Fix add_maintenance_sheet.dart (Icons.remove_circle color)
with open('lib/features/maintenance/presentation/widgets/add_maintenance_sheet.dart', 'r') as f:
    content = f.read()

content = content.replace(
    "icon: Icon(\n                                    Icons.remove_circle,\n                                    color: dc?.dangerColor ?? Colors.red,\n                                  ),",
    "icon: Icon(\n                                    Icons.remove_circle,\n                                    color: Theme.of(context).colorScheme.error,\n                                  ),"
)

with open('lib/features/maintenance/presentation/widgets/add_maintenance_sheet.dart', 'w') as f:
    f.write(content)

# 2. Fix maintenance_history_screen.dart (const constructors)
with open('lib/features/maintenance/presentation/screens/maintenance_history_screen.dart', 'r') as f:
    content = f.read()

content = content.replace(
    "style: TextStyle(fontWeight: FontWeight.bold)",
    "style: const TextStyle(fontWeight: FontWeight.bold)"
)

content = content.replace(
    "title: Text('Confirmer la suppression')",
    "title: const Text('Confirmer la suppression')"
)

content = content.replace(
    "content: Text(\n                          'Voulez-vous vraiment supprimer cette maintenance ?',\n                        )",
    "content: const Text(\n                          'Voulez-vous vraiment supprimer cette maintenance ?',\n                        )"
)

content = content.replace(
    "child: Text('Annuler')",
    "child: const Text('Annuler')"
)

content = content.replace(
    "child: Text('Supprimer')",
    "child: const Text('Supprimer')"
)

with open('lib/features/maintenance/presentation/screens/maintenance_history_screen.dart', 'w') as f:
    f.write(content)
