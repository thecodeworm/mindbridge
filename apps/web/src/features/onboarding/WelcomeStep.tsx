import { moodColor } from '../../lib/moodColor'

export function WelcomeStep({ onNext }: { onNext: () => void }) {
  return (
    <div className="flex min-h-0 flex-col">
      <div className="min-h-0 flex-1 overflow-y-auto pb-8">
        <h1 className="text-4xl text-ink sm:text-5xl">A little space.<br /><span className="hl">Just for you.</span></h1>
        <p className="mt-4 text-lg leading-relaxed text-muted">A private space to check in with yourself, every day.</p>
        <p className="label mt-10">Every mood has a color</p>
        <div className="mt-3 grid grid-cols-5 gap-2">
          {['Heavy', 'Low', 'Okay', 'Good', 'Great'].map((word, i) => (
            <div key={word} className="flex flex-col items-center gap-2">
              <span className="aspect-square w-full rounded-lg" style={{ backgroundColor: moodColor(i * 2 + 1.5) }} />
              <span className="text-xs text-muted">{word}</span>
            </div>
          ))}
        </div>
      </div>
      <button type="button" onClick={onNext} className="w-full rounded-[10px] bg-blue-dark px-6 py-3.5 font-display font-extrabold text-on-accent hover:opacity-90">Get started</button>
    </div>
  )
}
