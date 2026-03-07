import re

with open('lib/features/terrain/presentation/widgets/terrain_health_gauge.dart', 'r') as f:
    content = f.read()

# Add import
import_stmt = "import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';\n"
if "dashboard_theme_extension.dart" not in content:
    content = content.replace("import 'package:flutter/material.dart';", f"import 'package:flutter/material.dart';\n{import_stmt}")

# Replacements
content = content.replace("  Color _getColor(int score) {", "  Color _getColor(int score, DashboardColors? dc) {")
content = content.replace("if (score >= 80) return Colors.green;", "if (score >= 80) return dc?.successColor ?? Colors.green;")
content = content.replace("if (score >= 50) return Colors.orange;", "if (score >= 50) return dc?.warningColor ?? Colors.orange;")
content = content.replace("return Colors.red;", "return dc?.dangerColor ?? Colors.red;")

content = content.replace("  @override\n  Widget build(BuildContext context) {", "  @override\n  Widget build(BuildContext context) {\n    final dc = Theme.of(context).extension<DashboardColors>();")
content = content.replace("final color = _getColor(score);", "final color = _getColor(score, dc);")

with open('lib/features/terrain/presentation/widgets/terrain_health_gauge.dart', 'w') as f:
    f.write(content)
