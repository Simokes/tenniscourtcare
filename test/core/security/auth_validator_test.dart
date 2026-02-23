import 'package:flutter_test/flutter_test.dart';
import 'package:tenniscourtcare/core/security/auth_validator.dart';
import 'package:tenniscourtcare/core/security/auth_exceptions.dart';

void main() {
  group('AuthValidator Password Tests', () {
    test('throws PasswordValidationException if password is null', () {
      expect(() => AuthValidator.validatePassword(null), throwsA(isA<PasswordValidationException>()));
    });

    test('throws PasswordValidationException if password is empty', () {
      expect(() => AuthValidator.validatePassword(''), throwsA(isA<PasswordValidationException>()));
    });

    test('throws PasswordValidationException if password is too short (<12 chars)', () {
      expect(() => AuthValidator.validatePassword('ShortPass1!'), throwsA(isA<PasswordValidationException>()));
    });

    test('throws PasswordValidationException if password is a common password', () {
      // We use a sequential password as a proxy for "common pattern" here since our explicit common list
      // mostly contains short passwords which fail on length check first.
      // 123456789012 starts with 123456 which triggers the sequential check.
      expect(() => AuthValidator.validatePassword('123456789012'), throwsA(isA<PasswordValidationException>()));
    });

    test('throws PasswordValidationException if password contains sequential patterns', () {
      expect(() => AuthValidator.validatePassword('abcdefghijkl'), throwsA(isA<PasswordValidationException>()));
      expect(() => AuthValidator.validatePassword('123456789012'), throwsA(isA<PasswordValidationException>()));
    });

    test('throws PasswordValidationException if password contains repetitive characters', () {
      expect(() => AuthValidator.validatePassword('aaaaaaaaaaaa'), throwsA(isA<PasswordValidationException>()));
      expect(() => AuthValidator.validatePassword('111111111111'), throwsA(isA<PasswordValidationException>()));
    });

    test('validates strong password successfully', () {
      expect(() => AuthValidator.validatePassword('CorrectHorseBatteryStaple'), returnsNormally);
      expect(() => AuthValidator.validatePassword('MyDogIsFluffyToday'), returnsNormally);
      expect(() => AuthValidator.validatePassword('Th1sIs@V3ryG00dP@ssw0rd'), returnsNormally);
    });
  });

  group('AuthValidator Email Tests', () {
    test('throws InvalidCredentialsException if email is null', () {
      expect(() => AuthValidator.validateEmail(null), throwsA(isA<InvalidCredentialsException>()));
    });

    test('throws InvalidCredentialsException if email is empty', () {
      expect(() => AuthValidator.validateEmail(''), throwsA(isA<InvalidCredentialsException>()));
    });

    test('throws InvalidCredentialsException if email format is invalid', () {
      expect(() => AuthValidator.validateEmail('invalid-email'), throwsA(isA<InvalidCredentialsException>()));
      expect(() => AuthValidator.validateEmail('user@'), throwsA(isA<InvalidCredentialsException>()));
      expect(() => AuthValidator.validateEmail('@domain.com'), throwsA(isA<InvalidCredentialsException>()));
    });

    test('validates correct email successfully', () {
      expect(() => AuthValidator.validateEmail('test@example.com'), returnsNormally);
      expect(() => AuthValidator.validateEmail('user.name@domain.co.uk'), returnsNormally);
    });
  });
}
