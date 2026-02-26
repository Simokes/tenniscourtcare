import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class StatsCarousel extends ConsumerWidget {
  final AsyncValue<int> todayMaintenanceCount;
  final AsyncValue<int> stockAlertCount;
  final AsyncValue<List<dynamic>> operationalTerrainsCount; // Ideally typed

  const StatsCarousel({
    super.key,
    required this.todayMaintenanceCount,
    required this.stockAlertCount,
    required this.operationalTerrainsCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 120, // Adjust height as needed
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _buildStatCard(
            context,
            icon: Icons.check_circle,
            iconColor: const Color(0xFF003580), // Primary
            value: operationalTerrainsCount.when(
              data: (list) => '${list.length}/20', // Placeholder total
              loading: () => '-',
              error: (_, __) => '!',
            ),
            label: 'Operational',
            onTap: () {
              // Could navigate to terrains/status list
            },
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            icon: Icons.construction,
            iconColor: const Color(0xFF0EA5E9), // Secondary
            value: todayMaintenanceCount.when(
              data: (val) => '$val',
              loading: () => '-',
              error: (_, __) => '!',
            ),
            label: 'Maintenance',
            onTap: () {
              context.push('/maintenance');
            },
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            icon: Icons.inventory_2,
            iconColor: Colors.orange,
            value: stockAlertCount.when(
              data: (val) => '$val',
              loading: () => '-',
              error: (_, __) => '!',
            ),
            label: 'Low Stocks',
            onTap: () {
              context.push('/stock');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
