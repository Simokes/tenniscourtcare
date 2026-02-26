// filepath: lib/data/models/user_entity_model.dart

import 'package:tenniscourtcare/domain/entities/user_entity.dart';
import 'package:tenniscourtcare/domain/enums/role.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';

class UserEntityModel {
  final int id;
  final String email;
  final String name;
  final String role; // Role.name
  final String? lastLoginAt; // ISO8601
  final String? avatarUrl;

  // Sync fields
  final String syncStatus;
  final String createdAt; // ISO8601
  final String updatedAt; // ISO8601
  final String? firebaseId;
  final String? createdBy;
  final String? modifiedBy;

  const UserEntityModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.lastLoginAt,
    this.avatarUrl,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.firebaseId,
    this.createdBy,
    this.modifiedBy,
  });

  /// JSON → Model
  factory UserEntityModel.fromJson(Map<String, dynamic> json) {
    return UserEntityModel(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      lastLoginAt: json['lastLoginAt'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      syncStatus: json['syncStatus'] as String? ?? 'LOCAL',
      createdAt:
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt:
          json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      firebaseId: json['firebaseId'] as String?,
      createdBy: json['createdBy'] as String?,
      modifiedBy: json['modifiedBy'] as String?,
    );
  }

  /// Model → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'lastLoginAt': lastLoginAt,
      'avatarUrl': avatarUrl,
      'syncStatus': syncStatus,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'firebaseId': firebaseId,
      'createdBy': createdBy,
      'modifiedBy': modifiedBy,
    };
  }

  /// Model → Domain Entity
  UserEntity toDomain() {
    return UserEntity(
      id: id,
      email: email,
      name: name,
      role: Role.values.byName(role),
      lastLoginAt: lastLoginAt != null ? DateTime.parse(lastLoginAt!) : null,
      avatarUrl: avatarUrl,
      syncStatus: SyncStatus.fromString(syncStatus),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      firebaseId: firebaseId,
      createdBy: createdBy,
      modifiedBy: modifiedBy,
    );
  }

  /// Domain Entity → Model
  factory UserEntityModel.fromDomain(UserEntity user) {
    return UserEntityModel(
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role.name,
      lastLoginAt: user.lastLoginAt?.toIso8601String(),
      avatarUrl: user.avatarUrl,
      syncStatus: user.syncStatus.name,
      createdAt: user.createdAt.toIso8601String(),
      updatedAt: user.updatedAt.toIso8601String(),
      firebaseId: user.firebaseId,
      createdBy: user.createdBy,
      modifiedBy: user.modifiedBy,
    );
  }
}
