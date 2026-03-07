with open('lib/features/inventory/presentation/screens/stock_history_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("const Icon(\n                        Icons.person_outline,\n                        size: 14,\n                        color: cs.onSurfaceVariant,\n                      ),", "Icon(\n                        Icons.person_outline,\n                        size: 14,\n                        color: cs.onSurfaceVariant,\n                      ),")

with open('lib/features/inventory/presentation/screens/stock_history_screen.dart', 'w') as f:
    f.write(content)
