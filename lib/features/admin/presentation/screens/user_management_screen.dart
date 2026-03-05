import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../../domain/enums/role.dart';
import '../../../../shared/widgets/premium/premium_card.dart';
import '../../../../shared/widgets/premium/premium_button.dart';
import '../../../../shared/widgets/premium/premium_text_field.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Gestion des membres'),
            centerTitle: false,
          ),
          usersAsync.when(
            data: (users) {
              if (users.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Aucun utilisateur')),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final user = users[index];
                    final isSelf = user.id == currentUser?.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PremiumCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isSelf
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer
                                      : Theme.of(
                                          context,
                                        ).colorScheme.secondaryContainer,
                                  child: Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: isSelf
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        user.email,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelf
                                        ? Theme.of(context).colorScheme.primary
                                              .withValues(alpha: 0.1)
                                        : Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(20),
                                    border: isSelf
                                        ? Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.2),
                                          )
                                        : null,
                                  ),
                                  child: Text(
                                    user.role.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: isSelf
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : null,
                                          fontWeight: isSelf
                                              ? FontWeight.bold
                                              : null,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            if (!isSelf) ...[
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _showResetPasswordDialog(
                                      context,
                                      ref,
                                      user.id,
                                      user.name,
                                    ),
                                    icon: const Icon(
                                      Icons.lock_reset,
                                      size: 18,
                                    ),
                                    label: const Text('Réinitialiser MDP'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _confirmDelete(
                                      context,
                                      ref,
                                      user.id,
                                      user.name,
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                    ),
                                    label: const Text('Supprimer'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }, childCount: users.length),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => const SliverFillRemaining(
              child: Center(child: Text('Erreur lors du chargement')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserSheet(context, ref),
        label: const Text('Nouveau membre'),
        icon: const Icon(Icons.person_add),
      ),
    );
  }

  void _showAddUserSheet(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    // Default role
    Role selectedRole = Role.agent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ajouter un membre',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PremiumTextField(
                    label: 'Nom complet',
                    controller: nameCtrl,
                    hint: 'Ex: Jean Dupont',
                  ),
                  const SizedBox(height: 16),
                  PremiumTextField(
                    label: 'Email',
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    hint: 'jean.dupont@club.com',
                  ),
                  const SizedBox(height: 16),
                  PremiumTextField(
                    label: 'Mot de passe initial',
                    controller: passCtrl,
                    obscureText: true,
                    hint: 'Minimum 12 caractères',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Rôle',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<Role>(
                    segments: const [
                      ButtonSegment(
                        value: Role.agent,
                        label: Text('Agent / Jardinier'),
                        icon: Icon(Icons.engineering),
                      ),
                      ButtonSegment(
                        value: Role.admin,
                        label: Text('Administrateur'),
                        icon: Icon(Icons.admin_panel_settings),
                      ),
                    ],
                    selected: {selectedRole},
                    onSelectionChanged: (Set<Role> newSelection) {
                      setState(() {
                        selectedRole = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: PremiumButton(
                      label: 'Créer le compte',
                      onPressed: () async {
                        if (nameCtrl.text.isEmpty ||
                            emailCtrl.text.isEmpty ||
                            passCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Veuillez remplir tous les champs'),
                            ),
                          );
                          return;
                        }

                        try {
                          await ref
                              .read(userManagementControllerProvider.notifier)
                              .createUser(
                                email: emailCtrl.text.trim(),
                                name: nameCtrl.text.trim(),
                                password: passCtrl.text,
                                role: selectedRole,
                              );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Utilisateur créé avec succès'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur: ${e.toString()}'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int userId,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le compte de $name ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(userManagementControllerProvider.notifier)
                    .deleteUser(userId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Compte de $name supprimé')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(
    BuildContext context,
    WidgetRef ref,
    int userId,
    String name,
  ) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Réinitialiser MDP pour $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez le nouveau mot de passe :'),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (passCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref
                    .read(userManagementControllerProvider.notifier)
                    .resetPassword(userId, passCtrl.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mot de passe mis à jour')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }
}
