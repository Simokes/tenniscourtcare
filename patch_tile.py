import re

with open('lib/features/inventory/presentation/widgets/stock_item_tile.dart', 'r') as f:
    content = f.read()

# Add import
import_stmt = "import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';\n"
if "dashboard_theme_extension.dart" not in content:
    content = content.replace("import './add_edit_stock_item_sheet.dart';", f"import './add_edit_stock_item_sheet.dart';\n{import_stmt}")

# Add declarations
decl = """    final isLow = item.isLowOnStock;
    final cs = Theme.of(context).colorScheme;
    final dc = Theme.of(context).extension<DashboardColors>();
"""
content = content.replace("    final isLow = item.isLowOnStock;", decl)

# Replacements
content = content.replace("color: isLow ? Colors.red.shade100 : Colors.blue.shade50,", "color: isLow ? (dc?.dangerBgColor ?? Colors.red.shade100) : cs.surfaceContainerHighest,")
content = content.replace("color: isLow ? Colors.red.shade600 : Colors.blue.shade800,", "color: isLow ? (dc?.dangerColor ?? Colors.red) : cs.primary,")
content = content.replace("color: isLow ? Colors.red.shade800 : Colors.grey.shade900,", "color: isLow ? (dc?.dangerColor ?? Colors.red) : cs.onSurface,")
content = content.replace("""color: isLow
                            ? Colors.red.shade400
                            : Colors.grey.shade500,""", """color: isLow
                            ? (dc?.dangerColor ?? Colors.red)
                            : cs.onSurfaceVariant,""")
content = content.replace("color: Colors.red.shade600,", "color: dc?.dangerColor ?? Colors.red,")
content = content.replace("color: Colors.grey.shade500,", "color: cs.onSurfaceVariant,")
content = content.replace("color: Colors.white,", "color: cs.surface,")
content = content.replace("""color: isLow ? Colors.red.shade200 : Colors.grey.shade300,""", """color: isLow ? (dc?.dangerColor ?? Colors.red).withValues(alpha: 0.5) : cs.outlineVariant,""")
content = content.replace("""color: isLow
                          ? Colors.red.shade600
                          : Theme.of(context).primaryColor,""", """color: isLow
                          ? (dc?.dangerColor ?? Colors.red)
                          : Theme.of(context).primaryColor,""")

with open('lib/features/inventory/presentation/widgets/stock_item_tile.dart', 'w') as f:
    f.write(content)
