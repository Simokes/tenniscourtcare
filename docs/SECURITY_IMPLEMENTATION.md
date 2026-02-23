# Implementation Guide: Security Upgrades

This guide details the steps taken to secure the authentication system and how to work with the new components.

## 1. New Components Overview

| Component | Path | Description |
|-----------|------|-------------|
| `TokenService` | `lib/core/security/token_service.dart` | Handles JWT creation and verification. |
| `RateLimiter` | `lib/core/security/rate_limiter.dart` | Manages brute force protection (Login + OTP). |
| `AuthValidator` | `lib/core/security/auth_validator.dart` | Enforces NIST 2024 password & email rules. |
| `AuditRepository` | `lib/data/repositories/audit_repository.dart` | Interface for logging security events to DB. |
| `AuthExceptions` | `lib/core/security/auth_exceptions.dart` | Custom exception hierarchy for auth errors. |

## 2. Database Changes (Migration v9 & v10)

New tables added:
- `audit_logs`: Stores security events.
- `login_attempts`: Stores login attempts for persistent rate limiting.
- `otp_records`: Stores hashed OTPs with expiration.

**Migration Logic:**
Located in `lib/data/database/app_database.dart` inside `onUpgrade`.
```dart
if (from < 9) {
  await m.createTable(auditLogs);
  await m.createTable(loginAttempts);
}
if (from < 10) {
  await m.createTable(otpRecords);
}
```

## 3. How to Use

### dependency Injection
The new services are provided via Riverpod in `lib/presentation/providers/security_providers.dart`.
`AuthRepositoryImpl` now requires these services in its constructor.

### Sign In Flow
1. **Validator:** `AuthValidator.validateEmail` checks format.
2. **Rate Limiter:** `_rateLimiter.checkLimit` verifies if user is locked out.
3. **DB Lookup:** Fetches user. If not found -> Record Failure -> Throw.
4. **Verification:** `_verifyPassword` (Constant-Time) checks hash. If fail -> Record Failure -> Throw.
5. **Success:**
   - `_rateLimiter.recordAttempt(success: true)`
   - `_auditRepository.logEvent('LOGIN_SUCCESS')`
   - `_tokenService.createToken` returns JWT.
   - Token stored in `FlutterSecureStorage`.

### OTP Flow
1. **Request:** `AuthRepository.requestOtp(email)`
   - Checks rate limit (3/10min).
   - Generates secure random 6-digit code.
   - Hashes code and stores in DB (valid 5 min).
   - Logs `OTP_REQUESTED`.
2. **Verify:** `AuthRepository.verifyOtp(email, code)`
   - Fetches latest valid OTP record from DB.
   - Verifies hash constant-time.
   - If valid -> Deletes record -> Logs `OTP_VERIFY_SUCCESS` -> Returns true.

### Handling Exceptions
Wrap auth calls in `try-catch` blocks and handle specific exceptions:
```dart
try {
  await authNotifier.signIn(email, password);
} on AccountLockedException catch (e) {
  showError('Compte verrouillé jusqu\'à ${e.lockedUntil}');
} on InvalidCredentialsException {
  showError('Email ou mot de passe incorrect');
} catch (e) {
  showError('Erreur inconnue');
}
```

## 4. Testing
Run the security test suite:
```bash
flutter test test/core/security/auth_validator_test.dart
flutter test test/core/security/rate_limiter_test.dart
flutter test test/core/security/otp_test.dart
flutter test test/data/repositories/auth_repository_security_test.dart
```

## 5. Deployment
- **Dependencies:** Ensure `dart_jsonwebtoken` is in `pubspec.yaml`.
- **Database:** The app will automatically migrate the database on first launch.
- **Secrets:** In production, consider managing the JWT secret key more robustly (currently generated/stored in secure storage on first run).
