import re

with open('lib/features/terrain/presentation/screens/terrains_management_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("icon: const Icon(Icons.delete_outline, color: Colors.red),", "icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),")
content = content.replace("child: const Text('Supprimer', style: TextStyle(color: Colors.red)),", "child: Text('Supprimer', style: TextStyle(color: Theme.of(context).colorScheme.error)),")

with open('lib/features/terrain/presentation/screens/terrains_management_screen.dart', 'w') as f:
    f.write(content)
