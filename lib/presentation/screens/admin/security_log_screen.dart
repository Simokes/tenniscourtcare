import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_providers.dart';
import '../../../data/database/app_database.dart'; // Pour AuditLog
import '../../widgets/premium/premium_card.dart';

class SecurityLogScreen extends ConsumerWidget {
  const SecurityLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(securityLogsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Journal de sécurité'),
            centerTitle: false,
          ),
          logsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Aucun enregistrement')),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final log = logs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _LogItem(log: log),
                      );
                    },
                    childCount: logs.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Erreur lors du chargement des logs')),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  final AuditLog log;

  const _LogItem({required this.log});

  Color _getColor(BuildContext context) {
    final action = log.action.toUpperCase();
    if (action.contains('SUCCESS')) {
      return Colors.green.withOpacity(0.15); // Vert transparent
    } else if (action.contains('FAILED') || action.contains('ERROR')) {
      return Colors.red.withOpacity(0.15); // Rouge transparent
    } else if (action.contains('WARNING')) {
      return Colors.orange.withOpacity(0.15);
    }
    return Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5);
  }

  Color _getIconColor(BuildContext context) {
    final action = log.action.toUpperCase();
    if (action.contains('SUCCESS')) {
      return Colors.green;
    } else if (action.contains('FAILED') || action.contains('ERROR')) {
      return Colors.red;
    } else if (action.contains('WARNING')) {
      return Colors.orange;
    }
    return Theme.of(context).colorScheme.primary;
  }

  IconData _getIcon() {
    final action = log.action.toUpperCase();
    if (action.contains('LOGIN')) return Icons.login;
    if (action.contains('LOGOUT')) return Icons.logout;
    if (action.contains('OTP')) return Icons.password;
    if (action.contains('USER')) return Icons.person;
    if (action.contains('PASSWORD')) return Icons.lock_reset;
    return Icons.info_outline;
  }

  String _formatDetails(String? detailsJson) {
    if (detailsJson == null) return '';
    try {
      final Map<String, dynamic> map = jsonDecode(detailsJson);
      return map.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    } catch (_) {
      return detailsJson;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM HH:mm');

    return PremiumCard(
      color: _getColor(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getIcon(),
            color: _getIconColor(context),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        log.action,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      dateFormat.format(log.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (log.email != null)
                  Text(
                    log.email!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (log.details != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDetails(log.details),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace', // Pour différencier les détails techniques
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
