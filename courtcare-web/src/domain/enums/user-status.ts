export enum UserStatus {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  REJECTED = 'rejected'
}

export const userStatusLabels: Record<UserStatus, string> = {
  [UserStatus.ACTIVE]: 'Actif',
  [UserStatus.INACTIVE]: 'En attente de validation',
  [UserStatus.REJECTED]: 'Refusé'
};
