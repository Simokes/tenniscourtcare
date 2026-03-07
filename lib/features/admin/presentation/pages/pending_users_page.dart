import 'package:flutter/material.dart';
import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../../domain/entities/user_entity.dart';

class PendingUsersPage extends ConsumerWidget {
  const PendingUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingUsersAsync = ref.watch(pendingUsersProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Inscriptions en attente')),
      body: pendingUsersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Text(
                'Aucune inscription en attente',
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _UserCard(user: user);
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final UserEntity user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    user.role.label,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Inscrit le: ${dateFormat.format(user.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _confirmReject(context, ref),
                  icon: Icon(Icons.close, color: Theme.of(context).extension<DashboardColors>()?.dangerColor ?? Colors.red),
                  label: Text(
                    'Refuser',
                    style: TextStyle(color: Theme.of(context).extension<DashboardColors>()?.dangerColor ?? Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    if (user.firebaseId != null) {
                      ref
                          .read(userApprovalNotifierProvider.notifier)
                          .approveUser(user.firebaseId!);
                    }
                  },
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: Text('Approuver'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).extension<DashboardColors>()?.successColor ?? Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReject(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Refuser l\'inscription'),
        content: Text(
          'Êtes-vous sûr de vouloir refuser l\'inscription de ${user.name} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Refuser', style: TextStyle(color: Theme.of(context).extension<DashboardColors>()?.dangerColor ?? Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && user.firebaseId != null) {
      ref
          .read(userApprovalNotifierProvider.notifier)
          .rejectUser(user.firebaseId!);
    }
  }
}
