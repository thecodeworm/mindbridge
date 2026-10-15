import { describe, expect, test } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { CrisisChip } from './CrisisChip'

describe('CrisisChip', () => {
  test('renders a link to /help with the crisis-resources accessible name', () => {
    render(
      <MemoryRouter>
        <CrisisChip />
      </MemoryRouter>,
    )
    const link = screen.getByRole('link', { name: 'Crisis resources & help' })
    expect(link).toHaveAttribute('href', '/help')
  })
})
