enum Permission {
  // Gestion globale
  canAccessAdminDashboard,
  canManageUsers,
  canManageRoles,

  // Maintenance & Courts
  canManageCourts,
  canEditMaintenance,
  canViewMaintenanceHistory,

  // Planning
  canAccessPlanning,
  canManageReservations,

  // Stats & Reporting
  canSeeStats,
  canExportReports,

  // Communication
  canSendNotifications,

  // Profil
  canManageProfileSettings,
}
