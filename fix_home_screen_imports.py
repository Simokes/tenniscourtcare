import re

with open('lib/features/home/presentation/screens/home_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("package:tenniscourtcare/presentation/providers/dashboard_providers.dart", "package:tenniscourtcare/features/home/providers/dashboard_providers.dart")
content = content.replace("package:tenniscourtcare/presentation/providers/terrain_provider.dart", "package:tenniscourtcare/features/terrain/providers/terrain_provider.dart")
content = content.replace("package:tenniscourtcare/presentation/providers/stock_provider.dart", "package:tenniscourtcare/features/inventory/providers/stock_provider.dart")
content = content.replace("../widgets/weather_card.dart", "package:tenniscourtcare/features/weather/presentation/widgets/weather_card.dart")

with open('lib/features/home/presentation/screens/home_screen.dart', 'w') as f:
    f.write(content)
