// lib/domain/entities/user_entity.dart

import '../enums/role.dart';
import '../enums/user_status.dart';

class UserEntity {
  final int id;
  final String email;
  final String name;
  final Role role;
  final DateTime? lastLoginAt;
  final String? avatarUrl;
  final UserStatus status;
  final DateTime? approvedAt;
  final String? approvedBy;

  // Sync fields
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
    this.status = UserStatus.inactive,
    this.approvedAt,
    this.approvedBy,
    this.lastLoginAt,
    this.avatarUrl,
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
    UserStatus? status,
    DateTime? approvedAt,
    String? approvedBy,
    DateTime? lastLoginAt,
    String? avatarUrl,
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
      status: status ?? this.status,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      firebaseId: firebaseId ?? this.firebaseId,
      createdBy: createdBy ?? this.createdBy,
      modifiedBy: modifiedBy ?? this.modifiedBy,
    );
  }

  @override
  String toString() =>
      'UserEntity(id: $id, email: $email, role: ${role.name}, status: ${status.name}, createdAt: $createdAt, updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          name == other.name &&
          role == other.role &&
          status == other.status &&
          approvedAt == other.approvedAt &&
          approvedBy == other.approvedBy &&
          lastLoginAt == other.lastLoginAt &&
          avatarUrl == other.avatarUrl &&
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
      status.hashCode ^
      approvedAt.hashCode ^
      approvedBy.hashCode ^
      lastLoginAt.hashCode ^
      avatarUrl.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      firebaseId.hashCode ^
      createdBy.hashCode ^
      modifiedBy.hashCode;
}
