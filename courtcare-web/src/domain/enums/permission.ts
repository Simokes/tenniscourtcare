export enum Permission {
  // Gestion globale
  CAN_ACCESS_ADMIN_DASHBOARD = 'canAccessAdminDashboard',
  CAN_MANAGE_USERS = 'canManageUsers',
  CAN_MANAGE_ROLES = 'canManageRoles',

  // Maintenance & Courts
  CAN_MANAGE_COURTS = 'canManageCourts',
  CAN_EDIT_MAINTENANCE = 'canEditMaintenance',
  CAN_VIEW_MAINTENANCE_HISTORY = 'canViewMaintenanceHistory',

  // Planning
  CAN_ACCESS_PLANNING = 'canAccessPlanning',
  CAN_MANAGE_RESERVATIONS = 'canManageReservations',

  // Stats & Reporting
  CAN_SEE_STATS = 'canSeeStats',
  CAN_EXPORT_REPORTS = 'canExportReports',

  // Communication
  CAN_SEND_NOTIFICATIONS = 'canSendNotifications',

  // Profil
  CAN_MANAGE_PROFILE_SETTINGS = 'canManageProfileSettings',
}
