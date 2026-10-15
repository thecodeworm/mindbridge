import type { CSSProperties } from 'react'
import { moodColor } from '../../lib/moodColor'
import { NotebookIcon } from '../../components/NotebookIcon'

export function TrustStep({ onNext }: { onNext: () => void }) {
  return (
    <div className="flex min-h-0 flex-col">
      <div className="min-h-0 flex-1 overflow-y-auto pb-8">
        <h1 className="text-4xl text-ink sm:text-5xl">Your entries are<br /><span className="hl" style={{ '--mark': moodColor(3) } as CSSProperties}>private.</span></h1>
        <p className="mt-4 text-lg text-muted">Only you can see them.</p>
        <p className="label mt-8">Your space</p>
        <div className="card mt-2.5 flex items-start gap-4 p-5">
          <span className="text-blue-dark"><NotebookIcon name="lock" /></span>
          <p className="leading-relaxed text-muted">Not friends, not family, not even MindBridge staff can read your mood logs or journal entries. What you write here stays yours.</p>
        </div>
      </div>
      <button type="button" onClick={onNext} className="w-full rounded-[10px] bg-blue-dark px-6 py-3.5 font-display font-extrabold text-on-accent hover:opacity-90">Next</button>
    </div>
  )
}
