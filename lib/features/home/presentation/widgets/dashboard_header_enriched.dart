import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tenniscourtcare/features/terrain/providers/terrain_provider.dart';
import 'package:tenniscourtcare/features/weather/providers/weather_for_club_provider.dart';
import 'package:tenniscourtcare/shared/widgets/common/sync_status_indicator.dart';

/// Header du dashboard avec meteo compacte integree inline.
/// Remplace DashboardHeader en ajoutant la temperature et description meteo.
class DashboardHeaderEnriched extends ConsumerWidget {
  const DashboardHeaderEnriched({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final terrainsAsync = ref.watch(terrainsProvider);
    final terrains = terrainsAsync.valueOrNull ?? const [];

    AsyncValue<WeatherComputed?> weatherAsync = const AsyncValue.loading();
    if (terrains.isNotEmpty) {
      weatherAsync = ref.watch(weatherForClubProvider(terrains.first.type));
    }

    return SliverAppBar(
      pinned: true,
      backgroundColor: cs.surface.withValues(alpha: 0.95),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: cs.surfaceContainerHighest, height: 1.0),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.primary, // Primary
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.sports_tennis,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'CourtCare',
                      style: GoogleFonts.inter(
                        color: cs.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const Spacer(),
                    weatherAsync.when(
                      data: (weather) {
                        if (weather == null) return const SizedBox.shrink();

                        final temp = weather.context.snapshot.temperature.round();
                        final terrainType = terrains.isNotEmpty
                            ? terrains.first.type
                            : null;

                        return GestureDetector(
                          onTap: terrainType != null
                              ? () => context.push('/weather/${terrainType.name}')
                              : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                weather.conditionIcon,
                                size: 14,
                                color: weather.conditionColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$temp°C',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (err, _) {
                        debugPrint('Error loading weather inline: $err');
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const ConnectionStatusIndicator(mode: SyncIndicatorMode.compact),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: InkWell(
            onTap: () {
              context.push('/settings');
            },
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Icon(Icons.person, color: cs.primary, size: 22),
            ),
          ),
        ),
      ],
    );
  }
}
