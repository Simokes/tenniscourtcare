with open('lib/features/inventory/presentation/widgets/stock_alert_section.dart', 'r') as f:
    content = f.read()

content = content.replace("border: Border.all((dc?.dangerColor ?? Colors.red).withValues(alpha: 0.3)),", "border: Border.all(color: (dc?.dangerColor ?? Colors.red).withValues(alpha: 0.3)),")
content = content.replace("final cs = Theme.of(context).colorScheme;", "")

with open('lib/features/inventory/presentation/widgets/stock_alert_section.dart', 'w') as f:
    f.write(content)
