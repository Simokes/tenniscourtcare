export enum Role {
  ADMIN = 'admin',
  AGENT = 'agent',
  SECRETARY = 'secretary'
}

export type RoleKey = keyof typeof Role;

export const roleLabels: Record<Role, string> = {
  [Role.ADMIN]: 'Administrateur',
  [Role.AGENT]: 'Agent de maintenance',
  [Role.SECRETARY]: 'Secrétaire'
};

export const roleDescriptions: Record<Role, string> = {
  [Role.ADMIN]: 'Accès complet au système',
  [Role.AGENT]: 'Gestion des interventions et du planning',
  [Role.SECRETARY]: 'Gestion du planning et des réservations'
};
