import 'package:flutter_test/flutter_test.dart';
import 'package:tenniscourtcare/core/security/rate_limiter.dart';
import 'package:tenniscourtcare/data/repositories/audit_repository.dart';
import 'package:tenniscourtcare/core/security/auth_exceptions.dart';
import 'package:tenniscourtcare/data/database/app_database.dart'; // For LoginAttempt
import 'package:drift/drift.dart' as drift;

// Mock for AuditRepository
class MockAuditRepository implements AuditRepository {
  final List<LoginAttempt> _attempts = [];

  void setAttempts(List<LoginAttempt> attempts) {
    _attempts.clear();
    _attempts.addAll(attempts);
  }

  @override
  Future<List<LoginAttempt>> getRecentAttempts(String email, DateTime since) async {
    // Return attempts that match email and are after 'since'
    // Sorting by timestamp desc
    final matching = _attempts.where((a) => a.email == email && a.timestamp.isAfter(since)).toList();
    matching.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return matching;
  }

  @override
  Future<void> logLoginAttempt({required String email, required bool success, String? ipAddress}) async {
    _attempts.add(LoginAttempt(
      id: _attempts.length + 1,
      email: email,
      success: success,
      ipAddress: ipAddress,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Future<void> logEvent({required String action, String? email, int? userId, String? ipAddress, String? deviceInfo, Map<String, dynamic>? details}) async {
    // No-op for this test
  }

  @override
  Future<void> cleanOldAttempts(DateTime cutoff) async {}

  @override
  Future<int> countRecentOtps(String email, DateTime since) async {
    return 0; // Default 0
  }
}

void main() {
  late RateLimiter rateLimiter;
  late MockAuditRepository mockRepo;

  setUp(() {
    mockRepo = MockAuditRepository();
    rateLimiter = RateLimiter(mockRepo);
  });

  group('RateLimiter Tests', () {
    test('checkLimit allows first attempt', () async {
      await expectLater(rateLimiter.checkLimit('test@example.com'), completes);
    });

    test('locks out after 5 consecutive failures in memory', () async {
      final email = 'locked@example.com';

      // 5 failures
      for (int i = 0; i < 5; i++) {
        await rateLimiter.recordAttempt(email: email, success: false);
      }

      // Should throw
      expect(() => rateLimiter.checkLimit(email), throwsA(isA<AccountLockedException>()));
    });

    test('success resets memory count', () async {
      final email = 'reset@example.com';

      // 4 failures
      for (int i = 0; i < 4; i++) {
        await rateLimiter.recordAttempt(email: email, success: false);
      }

      // 1 success
      await rateLimiter.recordAttempt(email: email, success: true);

      // Should not throw (count reset)
      await expectLater(rateLimiter.checkLimit(email), completes);
    });

    test('locks out from DB history if memory is empty', () async {
      final email = 'db_lock@example.com';
      final now = DateTime.now();

      // Simulate 5 failures in DB within the last few minutes
      final attempts = List.generate(5, (i) => LoginAttempt(
        id: i,
        email: email,
        success: false,
        timestamp: now.subtract(Duration(minutes: i + 1)), // 1, 2, 3, 4, 5 mins ago
        ipAddress: '127.0.0.1'
      ));

      mockRepo.setAttempts(attempts);

      // Memory is empty (new instance logic simulated)
      // But checkLimit fetches from DB
      expect(() => rateLimiter.checkLimit(email), throwsA(isA<AccountLockedException>()));
    });

    test('does NOT lock out if DB has recent success breaking the chain', () async {
      final email = 'db_mixed@example.com';
      final now = DateTime.now();

      // 4 failures, then 1 success, then 4 failures (older)
      // Most recent is failure #4.
      // 4 failures -> Success -> ...
      // Should NOT lock.

      final attempts = [
        // Most recent
        LoginAttempt(id: 1, email: email, success: false, timestamp: now.subtract(const Duration(minutes: 1)), ipAddress: null),
        LoginAttempt(id: 2, email: email, success: false, timestamp: now.subtract(const Duration(minutes: 2)), ipAddress: null),
        LoginAttempt(id: 3, email: email, success: false, timestamp: now.subtract(const Duration(minutes: 3)), ipAddress: null),
        LoginAttempt(id: 4, email: email, success: false, timestamp: now.subtract(const Duration(minutes: 4)), ipAddress: null),
        // Break chain
        LoginAttempt(id: 5, email: email, success: true, timestamp: now.subtract(const Duration(minutes: 5)), ipAddress: null),
        // Older failures
        LoginAttempt(id: 6, email: email, success: false, timestamp: now.subtract(const Duration(minutes: 6)), ipAddress: null),
      ];

      mockRepo.setAttempts(attempts);

      await expectLater(rateLimiter.checkLimit(email), completes);
    });
  });
}
