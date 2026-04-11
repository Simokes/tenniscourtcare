import { Role, Permission, FeatureFlag } from '../enums';

// Définition statique des permissions par rôle (Single Source of Truth)
const rolePermissions: Record<Role, Permission[]> = {
  [Role.ADMIN]: Object.values(Permission), // Admin a tout
  [Role.AGENT]: [
    Permission.CAN_EDIT_MAINTENANCE,
    Permission.CAN_VIEW_MAINTENANCE_HISTORY,
    Permission.CAN_ACCESS_PLANNING,
    Permission.CAN_MANAGE_PROFILE_SETTINGS,
    Permission.CAN_SEE_STATS, // Accès stats basiques
  ],
  [Role.SECRETARY]: [
    Permission.CAN_ACCESS_PLANNING,
    Permission.CAN_MANAGE_RESERVATIONS,
    Permission.CAN_SEND_NOTIFICATIONS,
    Permission.CAN_VIEW_MAINTENANCE_HISTORY,
    Permission.CAN_MANAGE_PROFILE_SETTINGS,
  ],
};

// Feature Flags configuration
const featureFlags: Record<FeatureFlag, Role[]> = {
  [FeatureFlag.ADVANCED_STATS]: [Role.ADMIN],
  [FeatureFlag.USER_MANAGEMENT]: [Role.ADMIN],
  [FeatureFlag.MAINTENANCE_SCHEDULING]: [Role.ADMIN, Role.AGENT, Role.SECRETARY],
  [FeatureFlag.NOTIFICATIONS]: [Role.ADMIN, Role.SECRETARY],
};

/**
 * Vérifie si un rôle possède une permission spécifique
 */
export function hasPermission(role: Role, permission: Permission): boolean {
  const perms = rolePermissions[role] || [];
  return perms.includes(permission);
}

/**
 * Retourne toutes les permissions d'un rôle
 */
export function getPermissionsForRole(role: Role): Permission[] {
  return rolePermissions[role] || [];
}

/**
 * Vérifie si une feature est activée pour un rôle donné
 */
export function isFeatureEnabled(role: Role, flag: FeatureFlag): boolean {
  const allowedRoles = featureFlags[flag] || [];
  return allowedRoles.includes(role);
}
