import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_settings_provider.dart';
import '../providers/auth_providers.dart';
import '../widgets/settings_components.dart';
import 'edit_coords_page.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            title: const Text(
              'Paramètres',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blueGrey.shade800,
                      Colors.blueGrey.shade500,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),

              SettingsSection(
                title: 'Configuration du Club',
                children: [
                  settingsAsync.when(
                    data: (coords) {
                      final hasCoords = coords != null;
                      return SettingsTile(
                        icon: Icons.location_on,
                        title: 'Coordonnées GPS',
                        subtitle: hasCoords
                            ? '${coords.latitude.toStringAsFixed(4)}, ${coords.longitude.toStringAsFixed(4)}'
                            : 'Non définies',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditCoordsPage(),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Erreur: $e'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SettingsSection(
                title: 'Application',
                children: [
                  SettingsTile(
                    icon: Icons.dark_mode,
                    title: 'Mode sombre',
                    subtitle: 'À venir',
                    trailing: Switch(
                      value: false,
                      onChanged: (v) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsTile(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Alertes météo et stock',
                    trailing: Switch(value: true, onChanged: (v) {}),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SettingsSection(
                title: 'Données',
                children: [
                  SettingsTile(
                    icon: Icons.file_download,
                    title: 'Exporter les données',
                    subtitle: 'Format CSV',
                    onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Allez dans l\'écran Statistiques pour exporter')),
                        );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsTile(
                    icon: Icons.delete_forever,
                    title: 'Réinitialiser',
                    subtitle: 'Effacer toutes les données',
                    iconColor: Colors.red,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Attention'),
                          content: const Text('Voulez-vous vraiment tout effacer ? Cette action est irréversible.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                              },
                              child: const Text('Effacer', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SettingsSection(
                title: 'Compte',
                children: [
                  SettingsTile(
                    icon: Icons.logout,
                    title: 'Déconnexion',
                    subtitle: 'Quitter la session actuelle',
                    iconColor: Colors.orange.shade800,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Déconnexion'),
                          content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                ref.read(authStateProvider.notifier).signOut();
                                // La navigation vers Login est normalement gérée par le router (GoRouter)
                                // qui écoute isAuthenticatedProvider.
                              },
                              child: const Text('Se déconnecter'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 40),

              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.sports_tennis,
                      size: 48,
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tennis Court Care v1.0.0',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }
}
