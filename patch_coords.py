import re

with open('lib/features/terrain/presentation/screens/edit_coords_page.dart', 'r') as f:
    content = f.read()

content = content.replace("Future<void> _save() async {", "Future<void> _save() async {\n    final cs = Theme.of(context).colorScheme;")
content = content.replace("SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),", "SnackBar(content: Text('Erreur: $e'), backgroundColor: cs.error),")

with open('lib/features/terrain/presentation/screens/edit_coords_page.dart', 'w') as f:
    f.write(content)
