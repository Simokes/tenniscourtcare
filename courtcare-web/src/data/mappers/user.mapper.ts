import { User } from '../../domain/entities/user';
import { Role, UserStatus } from '../../domain/enums';
import { Timestamp } from 'firebase/firestore';

function parseTimestamp(ts: unknown): Date {
  if (ts instanceof Timestamp) {
    return ts.toDate();
  }
  if (typeof ts === 'string') {
    return new Date(ts);
  }
  return new Date();
}

export function firestoreToUser(id: string, data: Record<string, unknown>): User {
  return {
    id: Number(data['id'] ?? 0),
    email: String(data['email'] ?? ''),
    name: String(data['name'] ?? ''),
    role: Object.values(Role).includes(data['role'] as Role)
      ? (data['role'] as Role)
      : Role.AGENT,
    status: Object.values(UserStatus).includes(data['status'] as UserStatus)
      ? (data['status'] as UserStatus)
      : UserStatus.INACTIVE,
    lastLoginAt: data['lastLoginAt'] != null ? parseTimestamp(data['lastLoginAt']) : null,
    avatarUrl: data['avatarUrl'] != null ? String(data['avatarUrl']) : null,
    approvedAt: data['approvedAt'] != null ? parseTimestamp(data['approvedAt']) : null,
    approvedBy: data['approvedBy'] != null ? String(data['approvedBy']) : null,
    createdAt: parseTimestamp(data['createdAt']),
    updatedAt: parseTimestamp(data['updatedAt']),
    firebaseId: id,
    createdBy: data['createdBy'] != null ? String(data['createdBy']) : null,
    modifiedBy: data['modifiedBy'] != null ? String(data['modifiedBy']) : null,
  };
}

export function userToFirestore(user: User): Record<string, unknown> {
  const result: Record<string, unknown> = {
    email: user.email,
    name: user.name,
    role: user.role,
    status: user.status,
    createdAt: Timestamp.fromDate(user.createdAt),
    updatedAt: Timestamp.fromDate(user.updatedAt),
    firebaseId: user.firebaseId,
  };

  if (user.lastLoginAt !== null) result['lastLoginAt'] = Timestamp.fromDate(user.lastLoginAt);
  if (user.avatarUrl !== null) result['avatarUrl'] = user.avatarUrl;
  if (user.approvedAt !== null) result['approvedAt'] = Timestamp.fromDate(user.approvedAt);
  if (user.approvedBy !== null) result['approvedBy'] = user.approvedBy;
  if (user.createdBy !== null) result['createdBy'] = user.createdBy;
  if (user.modifiedBy !== null) result['modifiedBy'] = user.modifiedBy;

  return result;
}
