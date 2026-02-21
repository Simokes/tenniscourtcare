import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../../domain/enums/role.dart';

class RoleVisibility extends ConsumerWidget {
  final List<Role> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleVisibility({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user != null && allowedRoles.contains(user.role)) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}
