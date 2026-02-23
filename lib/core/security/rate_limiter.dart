import 'dart:async';
import '../../data/repositories/audit_repository.dart';
import '../../data/database/app_database.dart';
import '../security/auth_exceptions.dart';

class RateLimiter {
  final AuditRepository _auditRepository;

  // Configuration
  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  // Tier 1: In-memory tracking (Consecutive failures)
  // Key: Email, Value: List of failed attempt timestamps
  final Map<String, List<DateTime>> _memoryAttempts = {};

  RateLimiter(this._auditRepository);

  /// Checks if the user is currently rate limited.
  /// Throws [AccountLockedException] if locked.
  Future<void> checkLimit(String email) async {
    final now = DateTime.now();
    final cutoff = now.subtract(lockoutDuration);

    // 1. Check Memory (Fast path)
    if (_isRateLimitedInMemory(email, cutoff)) {
      final lockedUntil = _getLockoutEndTime(email);
      throw AccountLockedException(
        'Trop de tentatives échouées. Veuillez réessayer plus tard.',
        lockedUntil: lockedUntil,
      );
    }

    // 2. Check Database (Persistent path)
    // We fetch ALL attempts in the window to check for CONSECUTIVE failures.
    // If a success occurred, it resets the counter.
    final dbAttempts = await _auditRepository.getRecentAttempts(email, cutoff);

    // Check consecutive failures from the most recent
    int consecutiveFailures = 0;
    for (final attempt in dbAttempts) {
      if (attempt.success) {
        break; // Success resets the chain
      }
      consecutiveFailures++;
    }

    if (consecutiveFailures >= maxAttempts) {
      // Sync memory with DB state to avoid DB hits on next immediate retry
      // We populate memory with the timestamps of these failures
      final recentFailures = dbAttempts.take(consecutiveFailures).map((a) => a.timestamp).toList();
      _memoryAttempts[email] = recentFailures;

      throw AccountLockedException(
        'Compte temporairement verrouillé suite à de multiples échecs. Veuillez patienter 15 minutes.',
        lockedUntil: recentFailures.first.add(lockoutDuration),
      );
    }
  }

  /// Records an attempt (success or failure).
  /// [success] indicates if the login was successful.
  Future<void> recordAttempt({required String email, required bool success, String? ipAddress}) async {
    // Always log to DB for audit and Tier 2 tracking
    await _auditRepository.logLoginAttempt(email: email, success: success, ipAddress: ipAddress);

    if (success) {
      // Clear failures on success
      _memoryAttempts.remove(email);
    } else {
      // Add failure timestamp
      final attempts = _memoryAttempts[email] ?? [];
      attempts.add(DateTime.now());
      _memoryAttempts[email] = attempts;
    }

    _pruneMemory(email);
  }

  bool _isRateLimitedInMemory(String email, DateTime cutoff) {
    final attempts = _memoryAttempts[email];
    if (attempts == null) return false;

    // Filter attempts within window
    final recent = attempts.where((t) => t.isAfter(cutoff)).toList();
    return recent.length >= maxAttempts;
  }

  DateTime? _getLockoutEndTime(String email) {
    final attempts = _memoryAttempts[email];
    if (attempts == null || attempts.isEmpty) return null;
    return attempts.last.add(lockoutDuration);
  }

  void _pruneMemory(String email) {
    final attempts = _memoryAttempts[email];
    if (attempts == null) return;
    final cutoff = DateTime.now().subtract(lockoutDuration);
    // Keep only recent ones
    _memoryAttempts[email] = attempts.where((t) => t.isAfter(cutoff)).toList();
    if (_memoryAttempts[email]!.isEmpty) {
      _memoryAttempts.remove(email);
    }
  }
}
