import re

with open('lib/features/home/presentation/screens/home_screen.dart', 'r') as f:
    content = f.read()

# Replace missing consts
content = content.replace("SliverToBoxAdapter(\n            child: Padding(\n              padding: const EdgeInsets.only(bottom: 24),\n              child: WeatherCard()",
                          "const SliverToBoxAdapter(\n            child: Padding(\n              padding: EdgeInsets.only(bottom: 24),\n              child: WeatherCard()")

content = content.replace("SliverToBoxAdapter(\n            child: Padding(\n              padding: const EdgeInsets.only(bottom: 24)", "SliverToBoxAdapter(\n            child: const Padding(\n              padding: EdgeInsets.only(bottom: 24)")

with open('lib/features/home/presentation/screens/home_screen.dart', 'w') as f:
    f.write(content)
