import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/enums/role.dart';

class UserFirestoreModel {
  final String uid;
  final String email;
  final String name;
  final Role role;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? syncedAt;
  final String? profileImageUrl;
  final bool isActive;

  UserFirestoreModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.updatedAt,
    this.syncedAt,
    this.profileImageUrl,
    this.isActive = true,
  });

  factory UserFirestoreModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserFirestoreModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: _roleFromString(data['role']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      syncedAt: (data['syncedAt'] as Timestamp?)?.toDate(),
      profileImageUrl: data['profileImageUrl'],
      isActive: data['isActive'] ?? true,
    );
  }

  static Role _roleFromString(String? roleStr) {
    switch (roleStr?.toLowerCase()) {
      case 'admin':
        return Role.admin;
      case 'agent':
      case 'maintenance':
        return Role.agent;
      case 'secretary':
      case 'user':
        return Role.secretary; // Fallback
      default:
        return Role.secretary;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'syncedAt': syncedAt != null ? Timestamp.fromDate(syncedAt!) : null,
      'profileImageUrl': profileImageUrl,
      'isActive': isActive,
    };
  }
}
