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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium Gradient logic
    final gradientColors = isDark
        ? [const Color(0xFF1A1A1A), const Color(0xFF2C2C2C)]
        : [Colors.blueGrey.shade800, Colors.blueGrey.shade500];

    return Scaffold(
      // backgroundColor is handled by Theme
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
                    colors: gradientColors,
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
                    data: (settings) {
                      final loc = settings.location;
                      final hasCoords = loc != null;
                      return SettingsTile(
                        icon: Icons.location_on,
                        title: 'Coordonnées GPS',
                        subtitle: hasCoords
                            ? '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}'
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
                   settingsAsync.when(
                    data: (settings) => SettingsTile(
                      icon: Icons.brightness_6,
                      title: 'Apparence',
                      subtitle: _getThemeLabel(settings.themeMode),
                      onTap: () => _showThemeSelector(context, ref, settings.themeMode),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
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
                    iconColor: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
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
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tennis Court Care v1.0.0',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
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

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Système';
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
    }
  }

  void _showThemeSelector(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Choisir le thème',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.brightness_auto),
                title: const Text('Système'),
                trailing: currentMode == ThemeMode.system ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  ref.read(appSettingsProvider.notifier).setThemeMode(ThemeMode.system);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.light_mode),
                title: const Text('Clair'),
                trailing: currentMode == ThemeMode.light ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  ref.read(appSettingsProvider.notifier).setThemeMode(ThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Sombre'),
                trailing: currentMode == ThemeMode.dark ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  ref.read(appSettingsProvider.notifier).setThemeMode(ThemeMode.dark);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
