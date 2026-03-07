import re

with open('lib/features/inventory/presentation/widgets/stock_alert_section.dart', 'r') as f:
    content = f.read()

# Add import
import_stmt = "import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';\n"
if "dashboard_theme_extension.dart" not in content:
    content = content.replace("import './add_edit_stock_item_sheet.dart';", f"import './add_edit_stock_item_sheet.dart';\n{import_stmt}")

# Replacements
decl = """        if (criticalItems.isEmpty) return const SizedBox.shrink();

        final cs = Theme.of(context).colorScheme;
        final dc = Theme.of(context).extension<DashboardColors>();"""
content = content.replace("        if (criticalItems.isEmpty) return const SizedBox.shrink();", decl)

content = content.replace("color: Colors.red.shade50,", "color: dc?.dangerBgColor ?? Colors.red.shade50,")
content = content.replace("color: Colors.red.shade100", "(dc?.dangerColor ?? Colors.red).withValues(alpha: 0.3)")
content = content.replace("color: Colors.red.shade600,", "color: dc?.dangerColor ?? Colors.red,")
content = content.replace("color: Colors.red.shade900,", "color: dc?.dangerColor ?? Colors.red,")
content = content.replace("color: Colors.red.shade700,", "color: dc?.dangerColor ?? Colors.red,")
content = content.replace("backgroundColor: Colors.red.shade600,", "backgroundColor: dc?.dangerColor ?? Colors.red,")

with open('lib/features/inventory/presentation/widgets/stock_alert_section.dart', 'w') as f:
    f.write(content)
