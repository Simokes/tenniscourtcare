import re

with open('lib/features/home/presentation/screens/home_screen.dart', 'r') as f:
    content = f.read()

# Add imports if missing
if 'weather_for_club_provider' not in content:
    content = "import 'package:tenniscourtcare/features/weather/providers/weather_for_club_provider.dart';\n" + content
if 'package:tenniscourtcare/domain/entities/terrain.dart' not in content:
    content = "import 'package:tenniscourtcare/domain/entities/terrain.dart';\n" + content

# Replace WeatherCard() with the provider logic wrapped version, or add the logic to build().
logic = """    final terrains = terrainsAsync.valueOrNull ?? const <Terrain>[];
    final TerrainType? terrainType = terrains.isNotEmpty ? terrains.first.type : null;
    final weatherAsync = terrainType != null ? ref.watch(weatherForClubProvider(terrainType)) : const AsyncValue.loading();
"""
content = re.sub(r'(    final terrainsAsync = ref\.watch\(terrainsProvider\);)', r'\1\n' + logic, content)

weather_card_repl = """SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: weatherAsync.when(
                data: (weatherData) => WeatherCard(
                  weather: weatherData?.current,
                  precip24h: weatherData?.precip24h,
                  frozen: weatherData?.isFrozen,
                  unplayable: weatherData?.isUnplayable,
                  onRefresh: () => ref.refresh(weatherForClubProvider(terrainType!)),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => const Center(child: Text('Erreur météo')),
              ),
            ),
          )"""

# I need to find the `const SliverToBoxAdapter( child: Padding( ... WeatherCard() ... ) )` block and replace the whole block.
pattern = r"const\s+SliverToBoxAdapter\(\s*child:\s*Padding\(\s*padding:\s*EdgeInsets\.only\(bottom:\s*24\),\s*child:\s*WeatherCard\(\),\s*\),\s*\)"
content = re.sub(pattern, weather_card_repl, content, flags=re.MULTILINE)

with open('lib/features/home/presentation/screens/home_screen.dart', 'w') as f:
    f.write(content)
