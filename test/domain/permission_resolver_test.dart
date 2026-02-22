import 'package:flutter_test/flutter_test.dart';
import 'package:tenniscourtcare/domain/enums/role.dart';
import 'package:tenniscourtcare/domain/enums/permission.dart';
import 'package:tenniscourtcare/domain/logic/permission_resolver.dart';

void main() {
  group('PermissionResolver', () {
    test('Admin has all permissions', () {
      final perms = PermissionResolver.getPermissionsForRole(Role.admin);
      // Note: Permission.values is an Iterable, creating list for comparison
      expect(perms, containsAll(Permission.values));
    });

    test('Agent has specific permissions', () {
      final perms = PermissionResolver.getPermissionsForRole(Role.agent);
      expect(perms, contains(Permission.canEditMaintenance));
      // Agent should not manage users
      expect(perms, isNot(contains(Permission.canManageUsers)));
    });

    test('Secretary has specific permissions', () {
      final perms = PermissionResolver.getPermissionsForRole(Role.secretary);
      expect(perms, contains(Permission.canManageReservations));
      expect(perms, isNot(contains(Permission.canManageCourts)));
    });
  });
}
