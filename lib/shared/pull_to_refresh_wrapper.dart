import 'package:flutter/material.dart';

class PullToRefreshWrapper extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final ScrollController? scrollController;

  const PullToRefreshWrapper({
    super.key,
    required this.onRefresh,
    required this.child,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        try {
          await onRefresh();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Refresh failed: $e')));
          }
          rethrow;
        }
      },
      child: child,
    );
  }
}
