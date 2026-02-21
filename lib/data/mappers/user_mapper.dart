import '../database/app_database.dart';
import '../../domain/entities/user_entity.dart';

extension UserMapper on UserRow {
  UserEntity toDomain() {
    return UserEntity(
      id: id,
      email: email,
      name: name,
      role: role,
      lastLoginAt: lastLoginAt,
      avatarUrl: avatarUrl,
    );
  }
}
