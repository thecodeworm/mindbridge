// Unit tests for lib/core/validators.dart — pure password validation, no
// dependencies. Mirrors apps/web/src/lib/validators.test.ts (kept in sync
// since both files are documented as mirrors of each other).
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge/core/validators.dart';

void main() {
  group('validatePassword', () {
    test('null returns required error', () {
      expect(validatePassword(null), 'Password is required');
    });

    test('empty string returns required error', () {
      expect(validatePassword(''), 'Password is required');
    });

    test('below minimum length returns length error', () {
      expect(
        validatePassword('short'),
        'Password must be at least $kMinPasswordLength characters',
      );
    });

    test('exactly the minimum length with a letter and a number is valid', () {
      expect(validatePassword('abcdefg1'), isNull);
    });

    test('above the minimum length is valid', () {
      expect(validatePassword('a-very-long-password-2'), isNull);
    });

    test('letters only is rejected', () {
      expect(validatePassword('abcdefghij'), 'Password needs at least one letter and one number');
    });

    test('numbers only is rejected', () {
      expect(validatePassword('1234567890'), 'Password needs at least one letter and one number');
    });
  });

  group('validatePasswordConfirmation', () {
    test('null confirmation returns required error', () {
      expect(validatePasswordConfirmation(null, 'password1'), 'Please confirm your password');
    });

    test('empty confirmation returns required error', () {
      expect(validatePasswordConfirmation('', 'password1'), 'Please confirm your password');
    });

    test('mismatched confirmation returns mismatch error', () {
      expect(
        validatePasswordConfirmation('different', 'password1'),
        "Passwords don't match. Give that another try",
      );
    });

    test('matching confirmation is valid', () {
      expect(validatePasswordConfirmation('password1', 'password1'), isNull);
    });
  });
}
