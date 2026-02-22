import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_providers.dart';
import '../../../../domain/enums/role.dart';
import '../../widgets/premium/premium_card.dart';

class UserManagementSection extends ConsumerWidget {
  const UserManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Utilisateurs',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(allUsersProvider),
              ),
            ],
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
                  DataColumn(label: Text('Actions')),
                ],
                rows: users.map((user) {
                  return DataRow(cells: [
                    DataCell(Row(
                      children: [
                        CircleAvatar(child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')),
                        const SizedBox(width: 8),
                        Text(user.name),
                      ],
                    )),
                    DataCell(Text(user.email)),
                    DataCell(Chip(
                      label: Text(user.role.label),
                      backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                    )),
                    DataCell(PopupMenuButton<Role>(
                      onSelected: (newRole) {
                         ref.read(userManagementControllerProvider.notifier)
                            .updateUserRole(user.id, newRole);
                      },
                      itemBuilder: (context) => Role.values.map((role) {
                        return PopupMenuItem(
                          value: role,
                          child: Text(role.label),
                        );
                      }).toList(),
                      icon: const Icon(Icons.edit),
                    )),
                  ]);
                }).toList(),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Erreur: $err', style: const TextStyle(color: Colors.red)),
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
}
