import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogFirestoreModel {
  final String id;
  final String action;
  final String? userId;
  final String? userEmail;
  final DateTime timestamp;
  final String? ipAddress;
  final String? deviceInfo;
  final Map<String, dynamic>? details;
  final String? severity;

  AuditLogFirestoreModel({
    required this.id,
    required this.action,
    this.userId,
    this.userEmail,
    required this.timestamp,
    this.ipAddress,
    this.deviceInfo,
    this.details,
    this.severity,
  });

  factory AuditLogFirestoreModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLogFirestoreModel(
      id: doc.id,
      action: data['action'] ?? '',
      userId: data['userId'],
      userEmail: data['userEmail'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ipAddress: data['ipAddress'],
      deviceInfo: data['deviceInfo'],
      details: data['details'] as Map<String, dynamic>?,
      severity: data['severity'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'action': action,
      'userId': userId,
      'userEmail': userEmail,
      'timestamp': Timestamp.fromDate(timestamp),
      'ipAddress': ipAddress,
      'deviceInfo': deviceInfo,
      'details': details,
      'severity': severity,
    };
  }
}
