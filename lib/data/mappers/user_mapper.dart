import '../database/app_database.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/sync_status.dart';

extension UserMapper on UserRow {
  UserEntity toDomain() {
    return UserEntity(
      id: id,
      email: email,
      name: name,
      role: role,
      lastLoginAt: lastLoginAt,
      avatarUrl: avatarUrl,
      // Sync mappings
      createdAt:
          createdAt, // Table has withDefault(currentDateAndTime) so it should be non-null in Row
      updatedAt: updatedAt ?? createdAt,
      firebaseId: firestoreUid ?? remoteId,
      createdBy: null,
      modifiedBy: null,
      syncStatus: (firestoreUid != null || remoteId != null)
          ? SyncStatus.synced
          : SyncStatus.local,
    );
  }
}
