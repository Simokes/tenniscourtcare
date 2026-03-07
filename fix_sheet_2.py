with open('lib/features/inventory/presentation/widgets/add_edit_stock_item_sheet.dart', 'r') as f:
    content = f.read()

content = content.replace("borderRadius: BorderRadius.vertical(top: Radius.circular(24)),", "borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),")
content = content.replace("final dc = Theme.of(context).extension<DashboardColors>();\n\n    final categories =", "final categories =")

with open('lib/features/inventory/presentation/widgets/add_edit_stock_item_sheet.dart', 'w') as f:
    f.write(content)
