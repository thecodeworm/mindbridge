import { describe, expect, test, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { ActivityTagPicker } from './ActivityTagPicker'
import type { ActivityTag } from '../../../../shared/types'

function tag(id: string, label: string, emoji: string): ActivityTag {
  return { id, user_id: 'u1', slug: id, label, emoji, created_at: '2026-01-01T00:00:00Z' }
}

const TAGS = [tag('school', 'School', '📚'), tag('friends', 'Friends', '👥')]

describe('ActivityTagPicker', () => {
  test('renders nothing when tags is empty', () => {
    const { container } = render(
      <ActivityTagPicker tags={[]} selected={[]} onChange={() => {}} />,
    )
    expect(container).toBeEmptyDOMElement()
  })

  test('renders one button per tag with emoji + label', () => {
    render(<ActivityTagPicker tags={TAGS} selected={[]} onChange={() => {}} />)
    expect(screen.getByRole('button', { name: '📚School' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: '👥Friends' })).toBeInTheDocument()
  })

  test('tapping an unselected tag calls onChange with it added', async () => {
    const onChange = vi.fn()
    const user = userEvent.setup()
    render(<ActivityTagPicker tags={TAGS} selected={['school']} onChange={onChange} />)

    await user.click(screen.getByRole('button', { name: '👥Friends' }))

    expect(onChange).toHaveBeenCalledWith(['school', 'friends'])
  })

  test('tapping a selected tag calls onChange with it removed', async () => {
    const onChange = vi.fn()
    const user = userEvent.setup()
    render(<ActivityTagPicker tags={TAGS} selected={['school', 'friends']} onChange={onChange} />)

    await user.click(screen.getByRole('button', { name: '📚School' }))

    expect(onChange).toHaveBeenCalledWith(['friends'])
  })

  test('selected vs unselected tags carry different styling', () => {
    render(<ActivityTagPicker tags={TAGS} selected={['school']} onChange={() => {}} />)
    const selectedBtn = screen.getByRole('button', { name: '📚School' })
    const unselectedBtn = screen.getByRole('button', { name: '👥Friends' })

    expect(selectedBtn.className).toContain('border-blue-dark')
    expect(unselectedBtn.className).not.toContain('border-blue-dark')
  })
})
