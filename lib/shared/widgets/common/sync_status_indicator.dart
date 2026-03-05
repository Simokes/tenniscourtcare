import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/core/providers/connectivity_providers.dart';

enum SyncIndicatorMode { compact, detailed, minimal }

class ConnectionStatusIndicator extends ConsumerWidget {
  final SyncIndicatorMode mode;

  const ConnectionStatusIndicator({
    super.key,
    this.mode = SyncIndicatorMode.compact,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineStatusProvider).value ?? false;

    final IconData iconData = isOnline ? Icons.cloud_done : Icons.cloud_off;
    final Color color = isOnline ? Colors.green : Colors.grey;

    if (mode == SyncIndicatorMode.minimal) {
      return Icon(iconData, color: color, size: 20);
    } else if (mode == SyncIndicatorMode.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      );
    } else {
      return ListTile(
        leading: Icon(iconData, color: color),
        title: Text(isOnline ? 'Connected' : 'Disconnected'),
        subtitle: Text(isOnline ? 'Receiving real-time updates' : 'Working offline'),
      );
    }
  }
}
