import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sections/user_management_section.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/premium/premium_card.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authStateProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null)
              Text(
                'Bonjour, ${user.name}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 24),

            // Stats Row
            Row(
              children: [
                Expanded(child: _StatCard(title: 'Courts', value: '4', icon: Icons.sports_tennis)),
                const SizedBox(width: 16),
                Expanded(child: _StatCard(title: 'Interventions', value: '12', icon: Icons.handyman)),
                // Assuming we fetch these numbers from a provider later
              ],
            ),
            const SizedBox(height: 24),

            // User Management
            const UserManagementSection(),

            const SizedBox(height: 24),

          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title),
        ],
      ),
    );
  }
}
