import { describe, expect, test } from 'vitest'
import { validatePassword, validatePasswordConfirmation } from './validators'

describe('validatePassword', () => {
  test('empty string returns required error', () => {
    expect(validatePassword('')).toBe('Password is required.')
  })

  test('below minimum length returns length error', () => {
    expect(validatePassword('short')).toBe('Password must be at least 8 characters.')
  })

  test('exactly the minimum length with a letter and a number is valid', () => {
    expect(validatePassword('abcdefg1')).toBeNull()
  })

  test('above the minimum length is valid', () => {
    expect(validatePassword('a-very-long-password-2')).toBeNull()
  })

  test('letters only is rejected', () => {
    expect(validatePassword('abcdefghij')).toBe('Password needs at least one letter and one number.')
  })

  test('numbers only is rejected', () => {
    expect(validatePassword('1234567890')).toBe('Password needs at least one letter and one number.')
  })
})

describe('validatePasswordConfirmation', () => {
  test('empty confirmation returns required error', () => {
    expect(validatePasswordConfirmation('password1', '')).toBe('Please confirm your password.')
  })

  test('mismatched confirmation returns mismatch error', () => {
    expect(validatePasswordConfirmation('password1', 'different')).toBe(
      "Passwords don't match. Give that another try.",
    )
  })

  test('matching confirmation is valid', () => {
    expect(validatePasswordConfirmation('password1', 'password1')).toBeNull()
  })
})
