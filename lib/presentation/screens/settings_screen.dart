import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_settings_provider.dart';
import '../providers/auth_providers.dart';
import '../widgets/settings_components.dart';
import '../../domain/enums/role.dart';
import 'edit_coords_page.dart';
import 'admin/user_management_screen.dart';
import 'admin/security_log_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            ProfileCard(
              user: currentUser,
              onEdit: () {
                // Placeholder for edit profile functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Édition du profil à venir')),
                );
              },
            ),

            // Preferences Section
            const SectionHeader(title: 'Préférences'),
            SettingsContainer(
              children: [
                PreferenceTile(
                  icon: Icons.language,
                  title: 'Langue',
                  subtitle: 'Français',
                  onTap: () {}, // Visual only
                  trailing: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Français',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 56),
                settingsAsync.when(
                  data: (settings) => SwitchTile(
                    icon: isDark ? Icons.dark_mode : Icons.light_mode,
                    title: 'Mode sombre',
                    value: settings.themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const Divider(height: 1, indent: 56),
                settingsAsync.when(
                  data: (settings) {
                    final loc = settings.location;
                    final hasCoords = loc != null;
                    return PreferenceTile(
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
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),

            // Notifications Section
            const SectionHeader(title: 'Notifications'),
            SettingsContainer(
              children: [
                SwitchTile(
                  icon: Icons.notifications,
                  title: 'Notifications Push',
                  subtitle: 'Réservations et mises à jour',
                  value: true, // Dummy value
                  onChanged: (v) {},
                ),
                const Divider(height: 1, indent: 56),
                SwitchTile(
                  icon: Icons.mail,
                  title: 'Mises à jour par e-mail',
                  subtitle: 'Rapports mensuels et actualités',
                  value: false, // Dummy value
                  onChanged: (v) {},
                ),
              ],
            ),

            // Administration Section (Admin Only)
            if (currentUser?.role == Role.admin) ...[
              const SectionHeader(title: 'Administration'),
              SettingsContainer(
                children: [
                  PreferenceTile(
                    icon: Icons.manage_accounts,
                    title: 'Gestion des membres',
                    subtitle: 'Ajouter, supprimer, modifier',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserManagementScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  PreferenceTile(
                    icon: Icons.security,
                    title: 'Journal de sécurité',
                    subtitle: 'Audit des connexions',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SecurityLogScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],

            // Security & Data Section
            const SectionHeader(title: 'Sécurité'),
            SettingsContainer(
              children: [
                PreferenceTile(
                  icon: Icons.lock,
                  title: 'Changer le mot de passe',
                  onTap: () {
                    // Placeholder
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Changement de mot de passe à venir'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                PreferenceTile(
                  icon: Icons.file_download,
                  title: 'Exporter les données',
                  subtitle: 'Format CSV',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Allez dans l\'écran Statistiques pour exporter',
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                PreferenceTile(
                  icon: Icons.delete_forever,
                  title: 'Réinitialiser les données',
                  iconColor: Colors.red,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Attention'),
                        content: const Text(
                          'Voulez-vous vraiment tout effacer ? Cette action est irréversible.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              // Implement reset logic if needed
                            },
                            child: const Text(
                              'Effacer',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            // Logout Button
            const SizedBox(height: 16),
            LogoutButton(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Déconnexion'),
                    content: const Text(
                      'Voulez-vous vraiment vous déconnecter ?',
                    ),
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

            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.sports_tennis,
                    size: 32,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tennis Court Care v1.0.0',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
