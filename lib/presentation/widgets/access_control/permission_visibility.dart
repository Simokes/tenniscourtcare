import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/permission_provider.dart';
import '../../../domain/enums/permission.dart';

class PermissionVisibility extends ConsumerWidget {
  final Permission requiredPermission;
  final Widget child;
  final Widget? fallback;

  const PermissionVisibility({
    super.key,
    required this.requiredPermission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(hasPermissionProvider(requiredPermission));
    if (hasPermission) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}
