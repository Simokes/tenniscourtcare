/// Base class for all authentication related exceptions
abstract class AuthException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AuthException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AuthException: $message ${code != null ? "($code)" : ""}';
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException({String message = 'Email ou mot de passe incorrect.'})
      : super(message, code: 'INVALID_CREDENTIALS');
}

class AccountLockedException extends AuthException {
  final DateTime? lockedUntil;

  const AccountLockedException(String message, {this.lockedUntil})
      : super(message, code: 'ACCOUNT_LOCKED');
}

class SessionExpiredException extends AuthException {
  const SessionExpiredException({String message = 'La session a expiré. Veuillez vous reconnecter.'})
      : super(message, code: 'SESSION_EXPIRED');
}

class PasswordValidationException extends AuthException {
  const PasswordValidationException(String message)
      : super(message, code: 'WEAK_PASSWORD');
}

class UnauthorizedException extends AuthException {
  const UnauthorizedException({String message = 'Accès non autorisé.'})
      : super(message, code: 'UNAUTHORIZED');
}

class SecurityException extends AuthException {
  const SecurityException(String message, {dynamic originalError})
      : super(message, code: 'SECURITY_ERROR', originalError: originalError);
}
