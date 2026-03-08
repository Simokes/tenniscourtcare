import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_settings_provider.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../admin/providers/permission_provider.dart';
import '../widgets/settings_components.dart';
import '../widgets/profile_edit_sheet.dart';
import '../widgets/change_password_sheet.dart';
import '../../../../domain/enums/permission.dart';

/// Ecran des parametres de l'application.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = ref.watch(
      hasPermissionProvider(Permission.canAccessAdminDashboard),
    );
    final pendingCount = ref.watch(pendingCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Parametres',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION PROFIL ---
            ProfileCard(
              user: currentUser,
              onEditProfile:
                  () => showModalBottomSheet(
                    context: context,
                    useSafeArea: true,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => const ProfileEditSheet(),
                  ),
            ),

            // --- SECTION PREFERENCES ---
            const SectionHeader(title: 'Preferences'),
            SettingsContainer(
              children: [
                settingsAsync.when(
                  data:
                      (settings) => SwitchTile(
                        icon: isDark ? Icons.dark_mode : Icons.light_mode,
                        title: 'Mode sombre',
                        value: settings.themeMode == ThemeMode.dark,
                        onChanged: (value) {
                          ref
                              .read(appSettingsProvider.notifier)
                              .setThemeMode(
                                value ? ThemeMode.dark : ThemeMode.light,
                              );
                        },
                      ),
                  loading:
                      () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),

            // --- SECTION ADMINISTRATION (admin uniquement) ---
            if (isAdmin) ...[
              const SectionHeader(title: 'Administration'),
              if (pendingCount > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 18,
                          color:
                              Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$pendingCount utilisateur(s) en attente d\'approbation',
                            style: TextStyle(
                              color:
                                  Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SettingsContainer(
                children: [
                  PreferenceTile(
                    icon: Icons.admin_panel_settings,
                    title: 'Tableau de bord admin',
                    subtitle: 'Vue globale et gestion',
                    onTap: () => context.push('/admin'),
                  ),
                  const Divider(height: 1, indent: 56),
                  PreferenceTile(
                    icon: Icons.people,
                    title: 'Utilisateurs en attente',
                    subtitle: 'Approuver ou refuser les demandes',
                    onTap: () => context.push('/admin/pending-users'),
                    trailing:
                        pendingCount > 0
                            ? Badge(label: Text('$pendingCount'))
                            : Icon(
                              Icons.chevron_right,
                              color:
                                  Theme.of(context).iconTheme.color
                                      ?.withValues(alpha: 0.3),
                            ),
                  ),
                  const Divider(height: 1, indent: 56),
                  PreferenceTile(
                    icon: Icons.security,
                    title: 'Journal de securite',
                    subtitle: 'Audit des connexions',
                    onTap: () => context.push('/security-log'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // --- SECTION SECURITE ---
            const SectionHeader(title: 'Securite'),
            SettingsContainer(
              children: [
                PreferenceTile(
                  icon: Icons.lock,
                  title: 'Changer le mot de passe',
                  onTap:
                      () => showModalBottomSheet(
                        context: context,
                        useSafeArea: true,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) => const ChangePasswordSheet(),
                      ),
                ),
              ],
            ),

            // --- DECONNEXION ---
            LogoutButton(
              onTap: () {
                showDialog(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text('Deconnexion'),
                        content: const Text(
                          'Voulez-vous vraiment vous deconnecter ?',
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
                            child: const Text('Se deconnecter'),
                          ),
                        ],
                      ),
                );
              },
            ),

            // --- FOOTER ---
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.sports_tennis,
                    size: 32,
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                      alpha: 0.2,
                    ),
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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
