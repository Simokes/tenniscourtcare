import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tenniscourtcare/shared/widgets/common/sync_status_indicator.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 2),
              const ConnectionStatusIndicator(mode: SyncIndicatorMode.compact),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: InkWell(
            onTap: () {
              context.push('/settings');
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Icon(Icons.person, color: cs.primary),
            ),
          ),
        ),
      ],
    );
  }
}
