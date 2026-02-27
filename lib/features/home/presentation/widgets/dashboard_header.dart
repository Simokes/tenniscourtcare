import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tenniscourtcare/presentation/widgets/sync_status_indicator.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: Colors.grey.shade50, height: 1.0),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF003580), // Primary Navy Blue
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
                  color: const Color(0xFF003580),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              const SyncStatusIndicator(mode: SyncIndicatorMode.compact),
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
                border: Border.all(color: Colors.grey.shade200),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAveFTSG7Js3Qh4mtwLcHsfwK8QNddL4vXcQtIvhtpXk5AwV6j6qm0KixzDkPknwONgawW4mXxxtFVhuoa9FOmiRARuEz4K1IXo8ftAfzWsASMydFoF-Q925MS2RXZFouHki-i9FEOf5AycGUnFcD9aPyDUd4HTI6A5CEmkQ1j0ki4dRCGVplnxyVlRZnsIFRJShl51WAVdYv8zfkQOd-WLJUizBTKCeiMYlhcjgUj4hq39Tq-s2D4wc_8ToiYfCh1DB7ws5sRU9Q_q',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

