import re

with open('lib/features/home/presentation/screens/home_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("SliverToBoxAdapter(\n            child: Padding(\n              padding: EdgeInsets.only(bottom: 24),\n              child: UpcomingEventsList(),\n            ),",
                          "const SliverToBoxAdapter(\n            child: Padding(\n              padding: EdgeInsets.only(bottom: 24),\n              child: UpcomingEventsList(),\n            ),")
content = content.replace("SliverToBoxAdapter(\n            child: Padding(\n              padding: EdgeInsets.only(bottom: 24),\n              child: StockAlertCard(),\n            ),",
                          "const SliverToBoxAdapter(\n            child: Padding(\n              padding: EdgeInsets.only(bottom: 24),\n              child: StockAlertCard(),\n            ),")

# Also the one wrapping weatherAsync should be:
content = content.replace("SliverToBoxAdapter(\n            child: const Padding(\n              padding: EdgeInsets.only(bottom: 24),\n              child: weatherAsync.when(",
                          "SliverToBoxAdapter(\n            child: Padding(\n              padding: const EdgeInsets.only(bottom: 24),\n              child: weatherAsync.when(")

with open('lib/features/home/presentation/screens/home_screen.dart', 'w') as f:
    f.write(content)
