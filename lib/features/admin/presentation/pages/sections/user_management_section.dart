import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_providers.dart';
import '../../../../auth/providers/auth_providers.dart';
import '../../../../../domain/enums/role.dart';
import '../../../../../domain/enums/user_status.dart';
import '../../../../../shared/widgets/premium/premium_card.dart';

class UserManagementSection extends ConsumerWidget {
  const UserManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    final pendingCount = ref.watch(pendingCountProvider);

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Utilisateurs',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(allUsersProvider),
              ),
            ],
          ),
          if (pendingCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '$pendingCount inscription(s) en attente',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          usersAsync.when(
            data: (users) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Nom')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Rôle')),
                  DataColumn(label: Text('Statut')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: users.map((user) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(user.name),
                          ],
                        ),
                      ),
                      DataCell(Text(user.email)),
                      DataCell(
                        Chip(
                          label: Text(user.role.label),
                          backgroundColor: _getRoleColor(
                            user.role,
                          ).withValues(alpha: 0.2),
                        ),
                      ),
                      DataCell(
                        Chip(
                          label: Text(user.status.name),
                          backgroundColor: _getStatusColor(
                            user.status,
                          ).withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: _getStatusColor(user.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action.startsWith('role:')) {
                              final newRole = Role.values.firstWhere(
                                (r) => r.name == action.split(':')[1],
                              );
                              ref
                                  .read(
                                    userManagementControllerProvider.notifier,
                                  )
                                  .updateUserRole(user.id, newRole);
                            } else if (action == 'delete') {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Confirmer'),
                                  content: const Text(
                                    'Voulez-vous vraiment supprimer cet utilisateur ?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        ref
                                            .read(
                                              userManagementControllerProvider
                                                  .notifier,
                                            )
                                            .deleteUser(
                                              user.id,
                                              user.firebaseId,
                                            );
                                      },
                                      child: const Text(
                                        'Supprimer',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else if (action == 'approve' &&
                                user.firebaseId != null) {
                              ref
                                  .read(userApprovalNotifierProvider.notifier)
                                  .approveUser(user.firebaseId!);
                            } else if (action == 'reject' &&
                                user.firebaseId != null) {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Confirmer'),
                                  content: const Text(
                                    'Voulez-vous vraiment refuser cet utilisateur ?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        ref
                                            .read(
                                              userApprovalNotifierProvider
                                                  .notifier,
                                            )
                                            .rejectUser(user.firebaseId!);
                                      },
                                      child: const Text(
                                        'Refuser',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) {
                            final items = <PopupMenuEntry<String>>[];

                            items.add(
                              const PopupMenuItem(
                                enabled: false,
                                child: Text(
                                  'Changer de rôle',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            );

                            for (var role in Role.values) {
                              items.add(
                                PopupMenuItem(
                                  value: 'role:${role.name}',
                                  child: Text(role.label),
                                ),
                              );
                            }

                            items.add(const PopupMenuDivider());

                            if (user.status == UserStatus.inactive &&
                                user.firebaseId != null) {
                              items.add(
                                const PopupMenuItem(
                                  value: 'approve',
                                  child: Text(
                                    'Approuver',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ),
                              );
                              items.add(
                                const PopupMenuItem(
                                  value: 'reject',
                                  child: Text(
                                    'Refuser',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              );
                              items.add(const PopupMenuDivider());
                            }

                            items.add(
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Supprimer',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            );

                            return items;
                          },
                          icon: const Icon(Icons.more_vert),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                Text('Erreur: $err', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(Role role) {
    switch (role) {
      case Role.admin:
        return Colors.purple;
      case Role.agent:
        return Colors.blue;
      case Role.secretary:
        return Colors.orange;
    }
  }

  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return Colors.green;
      case UserStatus.inactive:
        return Colors.orange;
      case UserStatus.rejected:
        return Colors.red;
    }
  }
}
