// lib/domain/entities/user_entity.dart

import '../enums/role.dart';
import 'sync_status.dart';

class UserEntity {
  final int id;
  final String email;
  final String name;
  final Role role;
  final DateTime? lastLoginAt;
  final String? avatarUrl;

  // Sync fields
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? firebaseId;
  final String? createdBy;
  final String? modifiedBy;

  UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.lastLoginAt,
    this.avatarUrl,
    this.syncStatus = SyncStatus.local,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.firebaseId,
    this.createdBy,
    this.modifiedBy,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Copie immuable pour les mises à jour
  UserEntity copyWith({
    int? id,
    String? email,
    String? name,
    Role? role,
    DateTime? lastLoginAt,
    String? avatarUrl,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? firebaseId,
    String? createdBy,
    String? modifiedBy,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      firebaseId: firebaseId ?? this.firebaseId,
      createdBy: createdBy ?? this.createdBy,
      modifiedBy: modifiedBy ?? this.modifiedBy,
    );
  }

  @override
  String toString() =>
      'UserEntity(id: $id, email: $email, role: ${role.name}, syncStatus: $syncStatus, createdAt: $createdAt, updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          name == other.name &&
          role == other.role &&
          lastLoginAt == other.lastLoginAt &&
          avatarUrl == other.avatarUrl &&
          syncStatus == other.syncStatus &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          firebaseId == other.firebaseId &&
          createdBy == other.createdBy &&
          modifiedBy == other.modifiedBy;

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      name.hashCode ^
      role.hashCode ^
      lastLoginAt.hashCode ^
      avatarUrl.hashCode ^
      syncStatus.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      firebaseId.hashCode ^
      createdBy.hashCode ^
      modifiedBy.hashCode;
}
