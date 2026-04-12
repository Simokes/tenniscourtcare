import { Role, UserStatus } from '../enums';

export interface User {
  id: number;
  email: string;
  name: string;
  role: Role;
  status: UserStatus;
  lastLoginAt: Date | null;
  avatarUrl: string | null;
  approvedAt: Date | null;
  approvedBy: string | null;

  // Sync fields
  createdAt: Date;
  updatedAt: Date;
  firebaseId: string | null;
  createdBy: string | null;
  modifiedBy: string | null;
}

export type UpdateUserPayload = Partial<Omit<User, 'firebaseId'>>;
