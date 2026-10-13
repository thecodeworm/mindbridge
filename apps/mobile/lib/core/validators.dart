// Single source of truth for password rules on mobile — mirrored by
// apps/web/src/lib/validators.ts. Before this, sign_up_screen.dart and
// reset_password_screen.dart each carried their own inline 6-char closure
// with different copy.
//
// Only new and changed passwords go through these; existing 6-character test
// accounts keep working because Supabase never re-validates at login.
const int kMinPasswordLength = 8;

const String kPasswordHint = 'At least $kMinPasswordLength characters';

/// Returns an error message, or null when the password is acceptable.
/// Shaped as a Flutter `FormFieldValidator<String>`.
String? validatePassword(String? password) {
  if (password == null || password.isEmpty) return 'Password is required';
  if (password.length < kMinPasswordLength) {
    return 'Password must be at least $kMinPasswordLength characters';
  }
  return null;
}

/// Returns an error message, or null when the two entries match.
String? validatePasswordConfirmation(String? confirmPassword, String password) {
  if (confirmPassword == null || confirmPassword.isEmpty) {
    return 'Please confirm your password';
  }
  if (confirmPassword != password) {
    return "Passwords don't match. Give that another try";
  }
  return null;
}
