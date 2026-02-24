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
      role: Role.values.firstWhere(
        (e) => e.name == (data['role'] ?? 'user'),
        orElse: () => Role.user,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      syncedAt: (data['syncedAt'] as Timestamp?)?.toDate(),
      profileImageUrl: data['profileImageUrl'],
      isActive: data['isActive'] ?? true,
    );
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
