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
      onRefresh: onRefresh,
      child: child,
      // We can't force AlwaysScrollableScrollPhysics here easily if the child
      // is a pre-built ListView. The child must handle its physics
      // or be wrapped in a layout that ensures scrolling.
      // However, if the child is not scrollable (e.g. empty state),
      // RefreshIndicator won't work unless we wrap in SingleChildScrollView + physics.
      // But we don't know the child's nature.
      // We assume the child is a ScrollView.
    );
  }
}
