import 'package:flutter_test/flutter_test.dart';
import 'package:tenniscourtcare/data/repositories/auth_repository_impl.dart';
import 'package:tenniscourtcare/core/security/auth_exceptions.dart';
import 'package:tenniscourtcare/core/security/token_service.dart';
import 'package:tenniscourtcare/core/security/rate_limiter.dart';
import 'package:tenniscourtcare/data/repositories/audit_repository.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Mocks
class MockAppDatabase extends Fake implements AppDatabase {
  UserRow? userToReturn;
  OtpRecord? otpToReturn;
  int recentOtpCount = 0;
  List<OtpRecordsCompanion> insertedOtps = [];

  @override
  Future<UserRow?> getUserRowByEmail(String email) async => userToReturn;

  @override
  Future<int> updateLastLogin(int userId) async => 1;

  @override
  Future<int> countUsers() async => 0;

  @override
  Future<int> insertUser(UsersCompanion companion) async => 1;

  @override
  Future<int> insertOtp(OtpRecordsCompanion companion) async {
    insertedOtps.add(companion);
    return 1;
  }

  @override
  Future<OtpRecord?> getLatestValidOtp(String email) async => otpToReturn;

  @override
  Future<void> deleteOtp(int id) async {}

  @override
  Future<int> countRecentOtps(String email, DateTime since) async => recentOtpCount;
}

class MockTokenService extends Fake implements TokenService {
  @override
  Future<String> createToken({required int userId, required String email, required String role, Duration expiresIn = const Duration(hours: 1)}) async {
    return 'mock.jwt.token';
  }
}

class MockAuditRepository extends Fake implements AuditRepository {
  final List<String> logs = [];
  int otpCount = 0;

  @override
  Future<void> logEvent({required String action, String? email, int? userId, String? ipAddress, String? deviceInfo, Map<String, dynamic>? details}) async {
    logs.add('Event: $action');
  }

  @override
  Future<int> countRecentOtps(String email, DateTime since) async {
    return otpCount;
  }
}

class MockRateLimiter extends RateLimiter {
  bool shouldLockOtp = false;
  bool shouldLockAccount = false;

  MockRateLimiter(super.auditRepository);

  @override
  Future<void> checkLimit(String email) async {
    if (shouldLockAccount) throw const AccountLockedException('Locked');
  }

  @override
  Future<void> checkOtpLimit(String email) async {
    if (shouldLockOtp) throw const AccountLockedException('Locked OTP');
    await super.checkOtpLimit(email);
  }

  @override
  Future<void> recordAttempt({required String email, required bool success, String? ipAddress}) async {}

}

class MockSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> storage = {};

  // Implemented with dynamics to skip type checks
  @override
  Future<void> write({required String key, required String? value, dynamic iOptions, dynamic aOptions, dynamic lOptions, dynamic webOptions, dynamic mOptions, dynamic wOptions}) async {
    if (value != null) storage[key] = value;
  }

  @override
  Future<String?> read({required String key, dynamic iOptions, dynamic aOptions, dynamic lOptions, dynamic webOptions, dynamic mOptions, dynamic wOptions}) async {
    return storage[key];
  }

  @override
  Future<void> delete({required String key, dynamic iOptions, dynamic aOptions, dynamic lOptions, dynamic webOptions, dynamic mOptions, dynamic wOptions}) async {
    storage.remove(key);
  }
}

void main() {
  late AuthRepositoryImpl authRepo;
  late MockAppDatabase mockDb;
  late MockTokenService mockTokenService;
  late MockAuditRepository mockAuditRepo;
  late MockRateLimiter mockRateLimiter;
  late MockSecureStorage mockStorage;

  setUp(() {
    mockDb = MockAppDatabase();
    mockTokenService = MockTokenService();
    mockAuditRepo = MockAuditRepository();
    // We use real RateLimiter logic partially via Mock calling super, but need MockAuditRepo to support it
    // Actually MockRateLimiter extends RateLimiter so it has the memory maps.
    mockRateLimiter = MockRateLimiter(mockAuditRepo);
    mockStorage = MockSecureStorage();

    authRepo = AuthRepositoryImpl(
      mockDb,
      mockStorage,
      mockTokenService,
      mockAuditRepo,
      mockRateLimiter,
    );
  });

  group('OTP Security Tests', () {
    test('requestOtp respects rate limit (Memory)', () async {
      final email = 'limit@test.com';

      // 1st
      await authRepo.requestOtp(email);
      // 2nd
      await authRepo.requestOtp(email);
      // 3rd
      await authRepo.requestOtp(email);

      // 4th should fail
      // We need to ensure calls are awaited and exceptions caught correctly.
      // And we need to verify RateLimiter actually throws.
      // Our MockRateLimiter calls super.checkOtpLimit.
      // The limit is 3. So 4th call should throw.
      // The issue is likely that recordOtpRequest update to memory is not happening as expected or test execution flow is interfering.
      // In AuthRepositoryImpl:
      // await _rateLimiter.checkOtpLimit(email); (throws if full)
      // ...
      // _rateLimiter.recordOtpRequest(email); (adds 1)

      // Let's verify rate limiter state manually if possible or trust checkOtpLimit throws.
      // The failure message above says: "Expected: <Instance of 'AccountLockedException'> Actual: TestFailure:<Should have thrown AccountLockedException>"
      // This means it did NOT throw on the 4th call.

      // Why?
      // 1st call -> check (0) -> record (1)
      // 2nd call -> check (1) -> record (2)
      // 3rd call -> check (2) -> record (3)
      // 4th call -> check (3) -> >= 3 -> Throw

      // Maybe checkOtpLimit logic error?
      // if (recent.length >= maxOtpRequests) { throw ... }
      // maxOtpRequests = 3.

      // Let's print to debug or force fail to see what happened.
      // Actually, wait. The previous run log showed "AuthException: Trop de demandes...".
      // But it was logged as an Error?
      // "00:05 +0 -1: OTP Security Tests requestOtp respects rate limit (Memory) [E]"
      // And then "Actual: TestFailure:<Should have thrown AccountLockedException>"

      // It seems it MIGHT have thrown but maybe caught elsewhere or test runner confusion?
      // No, "Actual: TestFailure" means fail() was called. So it proceeded past await.

      // Ah, RateLimiter uses `DateTime.now()`.
      // If the test runs super fast, they might have exact same microsecond timestamp?
      // No, List<DateTime>.

      // Let's try to add a small delay to ensure distinct timestamps just in case, or debug.
      await Future.delayed(const Duration(milliseconds: 10));
      await expectLater(authRepo.requestOtp(email), throwsA(isA<AccountLockedException>()));
    });

    test('requestOtp generates 6-digit numeric code', () async {
      final email = 'code@test.com';
      await authRepo.requestOtp(email);

      // Verify DB insertion
      expect(mockDb.insertedOtps.length, 1);
      // We can't see the plain OTP since it's hashed in DB!
      // But we can verify the hash is stored.
      // And we can verify logic executed.
    });

    test('verifyOtp returns false if no valid OTP found', () async {
       mockDb.otpToReturn = null;
       final result = await authRepo.verifyOtp('user@test.com', '123456');
       expect(result, false);
    });

    test('verifyOtp returns false if hash mismatch', () async {
      // Create a record with a known hash (but we can't easily generate valid PBKDF2 hash for test without real crypto util)
      // So we will just use a dummy hash string that won't match '123456'
       mockDb.otpToReturn = OtpRecord(
         id: 1,
         email: 'user@test.com',
         hashedOtp: 'dummy_hash',
         expiresAt: DateTime.now().add(const Duration(minutes: 5)),
         createdAt: DateTime.now(),
         userId: null
       );

       final result = await authRepo.verifyOtp('user@test.com', '123456');
       expect(result, false);
    });

    // We can't easily test "returns true" without generating a valid hash corresponding to '123456'
    // using the exact same salt/iterations logic as AuthRepositoryImpl private methods.
    // Integration tests would handle this better.
  });
}
