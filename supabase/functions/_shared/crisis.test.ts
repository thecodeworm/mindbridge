import { assertEquals } from 'jsr:@std/assert@1'
import { hasCrisisLanguage, normalizeForCrisis } from './crisis.ts'

Deno.test('hasCrisisLanguage - matches the original phrases', () => {
  for (
    const t of [
      'I want to kill myself',
      'thinking about suicide',
      'I feel suicidal',
      'I want to end my life',
      'I just want to die',
      'self-harm again',
      'I keep hurting myself',
    ]
  ) assertEquals(hasCrisisLanguage(t), true, t)
})

Deno.test('hasCrisisLanguage - tolerates case, punctuation and curly apostrophes', () => {
  assertEquals(hasCrisisLanguage('I can’t go on.'), true)
  assertEquals(hasCrisisLanguage('i cant go on'), true)
  assertEquals(hasCrisisLanguage("I DON'T WANT TO LIVE!!!"), true)
  assertEquals(hasCrisisLanguage('self...harm'), true)
})

Deno.test('hasCrisisLanguage - matches newer phrases and slang', () => {
  for (
    const t of [
      'i might take my own life',
      'honestly everyone would be better off without me',
      'kms',
      'i wanna unalive myself',
      'thinking about cutting myself',
      'my life is not worth living',
    ]
  ) assertEquals(hasCrisisLanguage(t), true, t)
})

Deno.test('hasCrisisLanguage - respects word boundaries and ignores ordinary text', () => {
  assertEquals(hasCrisisLanguage('the mskms report was long'), false)
  assertEquals(hasCrisisLanguage('Rough day at school but I am okay'), false)
  assertEquals(hasCrisisLanguage('this math test is killing me'), false)
  assertEquals(hasCrisisLanguage(''), false)
  assertEquals(hasCrisisLanguage(null), false)
  assertEquals(hasCrisisLanguage(undefined), false)
})

Deno.test('normalizeForCrisis - collapses punctuation and apostrophes', () => {
  assertEquals(normalizeForCrisis('Don’t   GO!!'), 'dont go')
})
