import './auth_exceptions.dart';

class AuthValidator {
  // NIST 2024:
  // - Favor length over complexity
  // - No composition rules (e.g. "must have 1 symbol")
  // - Check against common passwords/patterns

  static const int minPasswordLength = 12;

  // Patterns to block (sequential, repetitive)
  // 123456, abcdef, etc.
  static final _sequentialNumbers = RegExp(
    r'^(?:012345|123456|234567|345678|456789|567890|098765|987654|876543|765432|654321|543210)',
  );
  static final _sequentialLetters = RegExp(
    r'^(?:abcdef|bcdefg|cdefgh|defghi|efghij|fghijk|ghijkl|hijklm|ijklmn|jklmno|klmnop|lmnopq|mnopqr|nopqrs|opqrst|pqrstu|qrstuv|rstuvw|stuvwx|tuvwxy|uvwxyz)',
    caseSensitive: false,
  );
  static final _repetitiveChars = RegExp(
    r'(.)\1{4,}',
  ); // 5+ same chars in a row

  // Common weak passwords (simplified list for MVP, ideally use a bloom filter or larger list)
  static final _commonPasswords = {
    'password',
    '123456',
    '12345678',
    '123456789',
    'qwerty',
    'admin',
    'welcome',
    'login',
    'tennis',
    'court',
    'manager',
    'iloveyou',
  };

  static void validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      throw const PasswordValidationException('Le mot de passe est requis.');
    }

    if (password.length < minPasswordLength) {
      throw const PasswordValidationException(
        'Le mot de passe doit contenir au moins $minPasswordLength caractères.',
      );
    }

    final lower = password.toLowerCase();

    // Check against common list
    if (_commonPasswords.contains(lower)) {
      throw const PasswordValidationException(
        'Ce mot de passe est trop commun. Veuillez choisir une phrase secrète plus complexe.',
      );
    }

    // Check for sequential patterns
    if (_sequentialNumbers.hasMatch(password) ||
        _sequentialLetters.hasMatch(password)) {
      throw const PasswordValidationException(
        'Le mot de passe contient des séquences trop simples (ex: 123456, abcdef).',
      );
    }

    // Check for repetitive characters
    if (_repetitiveChars.hasMatch(password)) {
      throw const PasswordValidationException(
        'Le mot de passe contient trop de caractères répétitifs.',
      );
    }
  }

  static void validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      throw const InvalidCredentialsException(message: "L'email est requis.");
    }

    // Simple regex for email structure
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      throw const InvalidCredentialsException(
        message: "Format d'email invalide.",
      );
    }
  }

  static void validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      throw const InvalidCredentialsException(message: 'Le nom est requis.');
    }
  }
}
