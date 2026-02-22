import '../enums/role.dart';
import '../enums/permission.dart';
import '../enums/feature_flag.dart';

class PermissionResolver {
  // Définition statique des permissions par rôle (Single Source of Truth)
  static final Map<Role, List<Permission>> _rolePermissions = {
    Role.admin: Permission.values, // Admin a tout

    Role.agent: [
      Permission.canEditMaintenance,
      Permission.canViewMaintenanceHistory,
      Permission.canAccessPlanning,
      Permission.canManageProfileSettings,
      Permission.canSeeStats, // Accès stats basiques
    ],

    Role.secretary: [
      Permission.canAccessPlanning,
      Permission.canManageReservations,
      Permission.canSendNotifications,
      Permission.canViewMaintenanceHistory,
      Permission.canManageProfileSettings,
    ],
  };

  // Feature Flags configuration
  static final Map<FeatureFlag, List<Role>> _featureFlags = {
    FeatureFlag.advancedStats: [Role.admin],
    FeatureFlag.userManagement: [Role.admin],
    FeatureFlag.maintenanceScheduling: [Role.admin, Role.agent, Role.secretary],
    FeatureFlag.notifications: [Role.admin, Role.secretary],
  };

  /// Vérifie si un rôle possède une permission spécifique
  static bool hasPermission(Role role, Permission permission) {
    final perms = _rolePermissions[role] ?? [];
    return perms.contains(permission);
  }

  /// Retourne toutes les permissions d'un rôle
  static List<Permission> getPermissionsForRole(Role role) {
    return _rolePermissions[role] ?? [];
  }

  /// Vérifie si une feature est activée pour un rôle donné
  static bool isFeatureEnabled(Role role, FeatureFlag flag) {
    final allowedRoles = _featureFlags[flag] ?? [];
    return allowedRoles.contains(role);
  }
}
