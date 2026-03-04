import '../database/app_database.dart';
import 'package:drift/drift.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/enums/user_status.dart';

extension UserMapper on UserRow {
  UserEntity toDomain() {
    return UserEntity(
      id: id,
      email: email,
      name: name,
      role: role,
      status: UserStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => UserStatus.inactive,
      ),
      approvedAt: approvedAt,
      approvedBy: approvedBy,
      lastLoginAt: lastLoginAt,
      avatarUrl: avatarUrl,
      // Sync mappings
      createdAt:
          createdAt, // Table has withDefault(currentDateAndTime) so it should be non-null in Row
      updatedAt: updatedAt ?? createdAt,
      firebaseId: firestoreUid ?? remoteId,
      createdBy: null,
      modifiedBy: null,
    );
  }
}

extension UserEntityCompanionMapper on UserEntity {
  UsersCompanion toCompanion() {
    return UsersCompanion(
      email: Value(email),
      firestoreUid: Value(firebaseId),
      name: Value(name),
      role: Value(role),
      status: Value(status.name),
      approvedAt: Value(approvedAt),
      approvedBy: Value(approvedBy),
      lastLoginAt: Value(lastLoginAt),
      avatarUrl: Value(avatarUrl),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}
