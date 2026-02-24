import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationFirestoreModel {
  final String id;
  final String userId;
  final String terrainId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? syncedAt;
  final String? notes;

  ReservationFirestoreModel({
    required this.id,
    required this.userId,
    required this.terrainId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.syncedAt,
    this.notes,
  });

  factory ReservationFirestoreModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReservationFirestoreModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      terrainId: data['terrainId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      syncedAt: (data['syncedAt'] as Timestamp?)?.toDate(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'terrainId': terrainId,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'syncedAt': syncedAt != null ? Timestamp.fromDate(syncedAt!) : null,
      'notes': notes,
    };
  }
}
