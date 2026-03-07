with open('lib/features/inventory/presentation/widgets/add_edit_stock_item_sheet.dart', 'r') as f:
    content = f.read()

# Fix constant snackbars
content = content.replace("const SnackBar(\n              content: Text('✅ Article ajouté'),\n              backgroundColor: dc?.successColor ?? Colors.green,\n            )", "SnackBar(\n              content: const Text('✅ Article ajouté'),\n              backgroundColor: Theme.of(context).extension<DashboardColors>()?.successColor ?? Colors.green,\n            )")

content = content.replace("const SnackBar(\n              content: Text('✅ Article mis à jour'),\n              backgroundColor: dc?.successColor ?? Colors.green,\n            )", "SnackBar(\n              content: const Text('✅ Article mis à jour'),\n              backgroundColor: Theme.of(context).extension<DashboardColors>()?.successColor ?? Colors.green,\n            )")

content = content.replace("const SnackBar(\n              content: Text('✅ Article supprimé'),\n              backgroundColor: dc?.successColor ?? Colors.green,\n            )", "SnackBar(\n              content: const Text('✅ Article supprimé'),\n              backgroundColor: Theme.of(context).extension<DashboardColors>()?.successColor ?? Colors.green,\n            )")

content = content.replace("const SnackBar(\n              content: Text('Impossible de supprimer: firebaseId manquant.'),\n              backgroundColor: cs.error,\n            )", "SnackBar(\n              content: const Text('Impossible de supprimer: firebaseId manquant.'),\n              backgroundColor: Theme.of(context).colorScheme.error,\n            )")

content = content.replace("child: const Text(\n                                'Supprimer',\n                                style: TextStyle(\n                                  color: cs.error,\n                                  fontWeight: FontWeight.bold,\n                                ),", "child: Text(\n                                'Supprimer',\n                                style: TextStyle(\n                                  color: cs.error,\n                                  fontWeight: FontWeight.bold,\n                                ),")

with open('lib/features/inventory/presentation/widgets/add_edit_stock_item_sheet.dart', 'w') as f:
    f.write(content)
