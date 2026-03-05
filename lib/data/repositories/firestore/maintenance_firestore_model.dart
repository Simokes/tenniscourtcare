import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceFirestoreModel {
  final String id;
  final String terrainId;
  final String type;
  final String status;
  final DateTime? scheduledDate;
  final DateTime? completedDate;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? syncedAt;

  MaintenanceFirestoreModel({
    required this.id,
    required this.terrainId,
    required this.type,
    required this.status,
    this.scheduledDate,
    this.completedDate,
    this.notes,
    this.createdBy,
    required this.createdAt,
    this.syncedAt,
  });

  factory MaintenanceFirestoreModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MaintenanceFirestoreModel(
      id: doc.id,
      terrainId: data['terrainId'] ?? '',
      type: data['type'] ?? '',
      status: data['status'] ?? 'scheduled',
      scheduledDate: (data['scheduledDate'] as Timestamp?)?.toDate(),
      completedDate: (data['completedDate'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      createdBy: data['createdBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      syncedAt: (data['syncedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'terrainId': terrainId,
      'type': type,
      'status': status,
      'scheduledDate': scheduledDate != null
          ? Timestamp.fromDate(scheduledDate!)
          : null,
      'completedDate': completedDate != null
          ? Timestamp.fromDate(completedDate!)
          : null,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'syncedAt': syncedAt != null ? Timestamp.fromDate(syncedAt!) : null,
    };
  }
}
