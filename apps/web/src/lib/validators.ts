// Single source of truth for password rules on web — mirrored by
// apps/mobile/lib/core/validators.dart. Before this, SignUpPage relied on a
// `minLength={6}` attribute and ResetPasswordPage on its own inline 6-char
// check, so the two screens disagreed about what a valid password was.
//
// Only new and changed passwords go through these; existing 6-character test
// accounts keep working because Supabase never re-validates at login.
export const MIN_PASSWORD_LENGTH = 8

export const PASSWORD_HINT = `At least ${MIN_PASSWORD_LENGTH} characters`

/** Returns an error message, or null when the password is acceptable. */
export function validatePassword(password: string): string | null {
  if (!password) return 'Password is required.'
  if (password.length < MIN_PASSWORD_LENGTH) {
    return `Password must be at least ${MIN_PASSWORD_LENGTH} characters.`
  }
  return null
}

/** Returns an error message, or null when the two entries match. */
export function validatePasswordConfirmation(
  password: string,
  confirmPassword: string,
): string | null {
  if (!confirmPassword) return 'Please confirm your password.'
  if (password !== confirmPassword) return "Passwords don't match — give that another try."
  return null
}
