import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/permission.dart';
import '../../domain/logic/permission_resolver.dart';
import 'auth_providers.dart';

final userPermissionsProvider = Provider<List<Permission>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return PermissionResolver.getPermissionsForRole(user.role);
});

final hasPermissionProvider = Provider.family<bool, Permission>((ref, permission) {
  final permissions = ref.watch(userPermissionsProvider);
  return permissions.contains(permission);
});
