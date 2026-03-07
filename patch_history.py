import re

with open('lib/features/inventory/presentation/screens/stock_history_screen.dart', 'r') as f:
    content = f.read()

# Add import
import_stmt = "import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';\n"
if "dashboard_theme_extension.dart" not in content:
    content = content.replace("import 'package:tenniscourtcare/shared/widgets/common/sync_status_indicator.dart';", f"import 'package:tenniscourtcare/shared/widgets/common/sync_status_indicator.dart';\n{import_stmt}")

# In build
content = content.replace("    final historyAsync = ref.watch(stockHistoryProvider);", "    final historyAsync = ref.watch(stockHistoryProvider);\n    final cs = Theme.of(context).colorScheme;")

# Replacements in build
content = content.replace("color: Colors.grey.shade400", "color: cs.onSurfaceVariant")
content = content.replace("color: Colors.grey.shade600,", "color: cs.onSurfaceVariant,")

# In _buildHistoryItem
decl = """    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dc = theme.extension<DashboardColors>();"""
content = content.replace("    final theme = Theme.of(context);", decl)

content = content.replace("final changeColor = isPositive ? Colors.green : Colors.red;", "final changeColor = isPositive ? (dc?.successColor ?? Colors.green) : (dc?.dangerColor ?? Colors.red);")
content = content.replace("color: Colors.grey.shade500,", "color: cs.onSurfaceVariant,")
content = content.replace("color: Colors.grey,", "color: cs.onSurfaceVariant,")

with open('lib/features/inventory/presentation/screens/stock_history_screen.dart', 'w') as f:
    f.write(content)
