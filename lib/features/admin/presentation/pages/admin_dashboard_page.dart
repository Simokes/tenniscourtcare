import 'package:flutter/material.dart';
import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import './sections/user_management_section.dart';
import './sections/terrain_management_section.dart';
import './sections/club_info_section.dart';
import '../../../auth/providers/auth_providers.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text('Administration'),
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Terrains'),
              Tab(text: 'Utilisateurs'),
              Tab(text: 'Club'),
            ],
          ),
          actions: [
            Consumer(
              builder: (context, ref, child) {
                final pendingCount = ref.watch(pendingCountProvider);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.group_add),
                      onPressed: () => context.push('/admin/pending-users'),
                    ),
                    if (pendingCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).extension<DashboardColors>()?.dangerColor ?? Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            pendingCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ref.read(authStateProvider.notifier).signOut();
              },
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: TerrainManagementSection(),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: UserManagementSection(),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ClubInfoSection(),
            ),
          ],
        ),
      ),
    );
  }
}
