import { describe, expect, test, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { FeltMoodSlider } from './FeltMoodSlider'

// Keyboard interaction only — deliberately avoids pointer-drag math, which
// relies on getBoundingClientRect() and jsdom doesn't lay out realistically.
describe('FeltMoodSlider', () => {
  test('ArrowRight/ArrowUp increases the value by 0.5', async () => {
    const onChange = vi.fn()
    const user = userEvent.setup()
    render(<FeltMoodSlider value={5} onChange={onChange} />)
    const slider = screen.getByRole('slider')
    slider.focus()

    await user.keyboard('{ArrowRight}')
    expect(onChange).toHaveBeenCalledWith(5.5)

    onChange.mockClear()
    await user.keyboard('{ArrowUp}')
    expect(onChange).toHaveBeenCalledWith(5.5)
  })

  test('Shift+ArrowRight increases the value by 1', async () => {
    const onChange = vi.fn()
    const user = userEvent.setup()
    render(<FeltMoodSlider value={5} onChange={onChange} />)
    screen.getByRole('slider').focus()

    await user.keyboard('{Shift>}{ArrowRight}{/Shift}')
    expect(onChange).toHaveBeenCalledWith(6)
  })

  test('ArrowLeft/ArrowDown decreases the value', async () => {
    const onChange = vi.fn()
    const user = userEvent.setup()
    render(<FeltMoodSlider value={5} onChange={onChange} />)
    const slider = screen.getByRole('slider')
    slider.focus()

    await user.keyboard('{ArrowLeft}')
    expect(onChange).toHaveBeenCalledWith(4.5)

    onChange.mockClear()
    await user.keyboard('{ArrowDown}')
    expect(onChange).toHaveBeenCalledWith(4.5)
  })

  test('Home and End jump to min and max', async () => {
    const onChange = vi.fn()
    const user = userEvent.setup()
    render(<FeltMoodSlider value={5} onChange={onChange} />)
    const slider = screen.getByRole('slider')
    slider.focus()

    await user.keyboard('{Home}')
    expect(onChange).toHaveBeenCalledWith(1)

    onChange.mockClear()
    await user.keyboard('{End}')
    expect(onChange).toHaveBeenCalledWith(10)
  })

  test('clamps at the max boundary', async () => {
    const onChange = vi.fn()
    const user = userEvent.setup()
    render(<FeltMoodSlider value={10} onChange={onChange} />)
    screen.getByRole('slider').focus()

    await user.keyboard('{ArrowRight}')
    expect(onChange).toHaveBeenCalledWith(10)
  })

  test('clamps at the min boundary', async () => {
    const onChange = vi.fn()
    const user = userEvent.setup()
    render(<FeltMoodSlider value={1} onChange={onChange} />)
    screen.getByRole('slider').focus()

    await user.keyboard('{ArrowLeft}')
    expect(onChange).toHaveBeenCalledWith(1)
  })

  test('aria-valuenow reflects the rounded current value', () => {
    render(<FeltMoodSlider value={7.4} onChange={() => {}} />)
    expect(screen.getByRole('slider')).toHaveAttribute('aria-valuenow', '7')
  })
})
