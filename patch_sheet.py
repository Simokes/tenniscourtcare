import re

with open('lib/features/inventory/presentation/widgets/add_edit_stock_item_sheet.dart', 'r') as f:
    content = f.read()

# Add import
import_stmt = "import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';\n"
if "dashboard_theme_extension.dart" not in content:
    content = content.replace("import 'package:tenniscourtcare/domain/entities/stock_item.dart';", f"import 'package:tenniscourtcare/domain/entities/stock_item.dart';\n{import_stmt}")

# Add declarations
decl = """  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dc = Theme.of(context).extension<DashboardColors>();
"""
content = content.replace("  @override\n  Widget build(BuildContext context) {", decl)

# Replacements
content = content.replace("const BoxDecoration(\n            color: Colors.white,", "BoxDecoration(\n            color: cs.surface,")
content = content.replace("color: Colors.grey[300],", "color: cs.onSurface.withValues(alpha: 0.2),")
content = content.replace("fillColor: Colors.grey.shade50,", "fillColor: cs.surfaceContainerHighest,")
content = content.replace("backgroundColor: Colors.green,", "backgroundColor: dc?.successColor ?? Colors.green,")
content = content.replace("backgroundColor: Colors.red,", "backgroundColor: cs.error,")
content = content.replace("side: const BorderSide(color: Colors.red),", "side: BorderSide(color: cs.error),")
content = content.replace("color: Colors.red,", "color: cs.error,")

with open('lib/features/inventory/presentation/widgets/add_edit_stock_item_sheet.dart', 'w') as f:
    f.write(content)
