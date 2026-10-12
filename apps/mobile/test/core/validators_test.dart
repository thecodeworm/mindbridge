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

    test('exactly the minimum length is valid', () {
      expect(validatePassword('a' * kMinPasswordLength), isNull);
    });

    test('above the minimum length is valid', () {
      expect(validatePassword('a-very-long-password'), isNull);
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
        "Passwords don't match — give that another try",
      );
    });

    test('matching confirmation is valid', () {
      expect(validatePasswordConfirmation('password1', 'password1'), isNull);
    });
  });
}
