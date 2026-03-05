import 'package:cloud_firestore/cloud_firestore.dart';
import './audit_log_firestore_model.dart';

class FirestoreAuditLogRepository {
  final FirebaseFirestore _firestore;

  FirestoreAuditLogRepository(this._firestore);

  CollectionReference get _auditLogs => _firestore.collection('auditLogs');

  Future<void> logAction(AuditLogFirestoreModel log) async {
    if (log.id.isEmpty) {
      await _auditLogs.add(log.toFirestore());
    } else {
      await _auditLogs.doc(log.id).set(log.toFirestore());
    }
  }

  Future<List<AuditLogFirestoreModel>> getRecentLogs({int limit = 50}) async {
    final query = await _auditLogs
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return query.docs
        .map((doc) => AuditLogFirestoreModel.fromFirestore(doc))
        .toList();
  }
}
