# Security Best Practices for TennisCourt Care

This document outlines the security standards and practices for developing and maintaining the TennisCourt Care application.

## Authentication & Authorization

### Password Policy (NIST 2024)
- **Minimum Length:** 12 characters.
- **Complexity:** Do NOT enforce specific character classes (e.g., "must contain 1 symbol").
- **Blocklist:** Block common passwords and simple patterns (e.g., "123456", "password").
- **Hashing:** Always use PBKDF2 (or stronger like Argon2) with a unique salt per user.
- **Comparison:** Always use constant-time comparison functions for hashes.

### Session Management
- **Tokens:** Use JWT (JSON Web Tokens) for session management.
- **Storage:** NEVER store tokens in `SharedPreferences` or `local_storage`. Use `FlutterSecureStorage`.
- **Expiration:** Tokens must have a short expiration time (e.g., 1 hour).
- **Validation:** Always verify the token signature and expiration on every sensitive action or app launch.

## Data Protection

### Data at Rest
- **Sensitive Data:** Encrypt sensitive fields in the database if possible (e.g., PII).
- **Local Database:** Do not enable Android Auto Backup (`android:allowBackup="false"`) unless data is encrypted.
- **Files:** Store sensitive files in internal storage, not external/public storage.

### Data in Transit
- **HTTPS:** Ensure all future API communications use TLS 1.2+.
- **Certificate Pinning:** Consider for high-security APIs.

## Input Validation
- **Trust No One:** Validate all inputs from users, even if they come from your own UI.
- **Sanitization:** Sanitize inputs before displaying them to prevent XSS (though Flutter renders text safely by default).
- **Type Checking:** Ensure data types match expectations (e.g., email format).

## Logging & Auditing
- **Audit Trail:** Log all security-critical events (login, logout, permission changes, failures) to the `AuditLogs` table.
- **No Secrets:** NEVER log passwords, tokens, or PII in debug logs or crash reports.
- **Monitoring:** Monitor `AuditLogs` for suspicious patterns (e.g., multiple failed logins from different IPs).

## Rate Limiting
- **Protection:** Apply rate limiting to all authentication endpoints (login, register, reset password).
- **Lockout:** Implement temporary account lockout after a threshold of failed attempts (e.g., 5 attempts).

## Dependencies
- **Updates:** Regularly run `flutter pub outdated` and update dependencies.
- **Vulnerability Scanning:** Check for known vulnerabilities in packages.

---
*Maintained by the Security Team.*
