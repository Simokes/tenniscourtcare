import os
import re

home_screen_path = "lib/features/home/presentation/screens/home_screen.dart"

if os.path.exists(home_screen_path):
    with open(home_screen_path, 'r') as f:
        content = f.read()

    # The weather card in home was at lib/features/home/presentation/widgets/weather_card.dart
    # The new one is at lib/features/weather/presentation/widgets/weather_card.dart
    # Let's replace the import if it exists

    # Actually wait, maybe it was a relative import in home_screen.dart?
    content = re.sub(r"import 'package:tenniscourtcare/features/home/presentation/widgets/weather_card\.dart';", "import 'package:tenniscourtcare/features/weather/presentation/widgets/weather_card.dart';", content)
    content = re.sub(r"import '\.\./widgets/weather_card\.dart';", "import 'package:tenniscourtcare/features/weather/presentation/widgets/weather_card.dart';", content)

    with open(home_screen_path, 'w') as f:
        f.write(content)

print("Updated home_screen.dart imports")
