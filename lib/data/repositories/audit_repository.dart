import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';

class AuditRepository {
  final AppDatabase _db;

  AuditRepository(this._db);

  Future<void> logEvent({
    required String action,
    String? email,
    int? userId,
    String? ipAddress,
    String? deviceInfo,
    Map<String, dynamic>? details,
  }) async {
    await _db.insertAuditLog(
      AuditLogsCompanion(
        action: Value(action),
        email: Value(email),
        userId: Value(userId),
        ipAddress: Value(ipAddress),
        deviceInfo: Value(deviceInfo),
        details: Value(details != null ? jsonEncode(details) : null),
        timestamp: Value(DateTime.now()),
      ),
    );
  }

  Future<void> logLoginAttempt({
    required String email,
    required bool success,
    String? ipAddress,
  }) async {
    await _db.insertLoginAttempt(
      LoginAttemptsCompanion(
        email: Value(email),
        success: Value(success),
        ipAddress: Value(ipAddress),
        timestamp: Value(DateTime.now()),
      ),
    );
  }

  Future<List<LoginAttempt>> getRecentAttempts(String email, DateTime since) {
    return _db.getRecentLoginAttempts(email, since);
  }

  Future<void> cleanOldAttempts(DateTime cutoff) {
    return _db.cleanOldLoginAttempts(cutoff);
  }

  Future<int> countRecentOtps(String email, DateTime since) {
    // This assumes AppDatabase has this method (added in migration)
    return _db.countRecentOtps(email, since);
  }

  Future<List<AuditLog>> getRecentAuditLogs({int limit = 100}) {
    return _db.getRecentAuditLogs(limit: limit);
  }
}
