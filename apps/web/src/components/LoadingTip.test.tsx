import { afterEach, beforeEach, describe, expect, test, vi } from 'vitest'
import { act, render, screen } from '@testing-library/react'
import { LoadingTip } from './LoadingTip'
import { LOADING_TIPS } from '../lib/loadingTips'

describe('LoadingTip', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })
  afterEach(() => {
    vi.useRealTimers()
  })

  test('renders the label and a tip from the list', () => {
    render(<LoadingTip />)
    expect(screen.getByText('Quick tip')).toBeInTheDocument()
    const shown = LOADING_TIPS.filter((tip) => screen.queryByText(tip))
    expect(shown).toHaveLength(1)
  })

  test('starts on the given index', () => {
    render(<LoadingTip startIndex={3} />)
    expect(screen.getByText(LOADING_TIPS[3])).toBeInTheDocument()
  })

  test('advances to the next tip after the interval', () => {
    render(<LoadingTip startIndex={0} />)
    expect(screen.getByText(LOADING_TIPS[0])).toBeInTheDocument()

    act(() => {
      vi.advanceTimersByTime(3999)
    })
    expect(screen.getByText(LOADING_TIPS[0])).toBeInTheDocument()

    act(() => {
      vi.advanceTimersByTime(1)
    })
    expect(screen.getByText(LOADING_TIPS[1])).toBeInTheDocument()
    expect(screen.queryByText(LOADING_TIPS[0])).not.toBeInTheDocument()
  })

  test('wraps from the last tip back to the first', () => {
    render(<LoadingTip startIndex={LOADING_TIPS.length - 1} />)
    expect(screen.getByText(LOADING_TIPS[LOADING_TIPS.length - 1])).toBeInTheDocument()
    act(() => {
      vi.advanceTimersByTime(4000)
    })
    expect(screen.getByText(LOADING_TIPS[0])).toBeInTheDocument()
  })

  test('honors a custom interval', () => {
    render(<LoadingTip startIndex={0} intervalMs={1000} />)
    act(() => {
      vi.advanceTimersByTime(1000)
    })
    expect(screen.getByText(LOADING_TIPS[1])).toBeInTheDocument()
  })

  test('announces changes politely', () => {
    const { container } = render(<LoadingTip startIndex={0} />)
    expect(container.querySelector('[aria-live="polite"]')).not.toBeNull()
  })

  test('clears its interval on unmount', () => {
    const { unmount } = render(<LoadingTip startIndex={0} />)
    expect(vi.getTimerCount()).toBe(1)
    unmount()
    expect(vi.getTimerCount()).toBe(0)
  })
})

describe('LOADING_TIPS', () => {
  test('has 12 tips', () => {
    expect(LOADING_TIPS).toHaveLength(12)
  })

  test('no tip contains an em dash or en dash', () => {
    for (const tip of LOADING_TIPS) {
      expect(tip).not.toMatch(/[—–]/)
    }
  })
})
