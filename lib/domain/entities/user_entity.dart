import '../enums/role.dart';

class UserEntity {
  final int id;
  final String email;
  final String name;
  final Role role;
  final DateTime? lastLoginAt;
  final String? avatarUrl;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.lastLoginAt,
    this.avatarUrl,
  });

  // Copie immuable pour les mises à jour
  UserEntity copyWith({
    int? id,
    String? email,
    String? name,
    Role? role,
    DateTime? lastLoginAt,
    String? avatarUrl,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  String toString() => 'UserEntity(id: $id, email: $email, role: ${role.name})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity && other.id == id && other.email == email;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}
