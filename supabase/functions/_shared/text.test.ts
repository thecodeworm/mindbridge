import { assertEquals } from 'jsr:@std/assert@1'
import { noDashes } from './text.ts'

Deno.test('noDashes replaces an em dash clause break with a comma', () => {
  assertEquals(
    noDashes('Breathe in slowly — then hold it.'),
    'Breathe in slowly, then hold it.',
  )
})

Deno.test('noDashes handles unspaced em dashes', () => {
  assertEquals(noDashes('Name it—out loud.'), 'Name it, out loud.')
})

Deno.test('noDashes turns numeric en dash ranges into "to"', () => {
  assertEquals(
    noDashes('Do this for 3–5 minutes.'),
    'Do this for 3 to 5 minutes.',
  )
})

Deno.test('noDashes leaves dash-free text and hyphens alone', () => {
  assertEquals(
    noDashes('A well-known 5-4-3-2-1 trick.'),
    'A well-known 5-4-3-2-1 trick.',
  )
})

Deno.test('noDashes drops a dash that ends a sentence', () => {
  assertEquals(noDashes('Keep going —.'), 'Keep going.')
})
