import { useNavigate } from 'react-router-dom'

interface Resource {
  name: string
  description: string
  call?: string
  text?: string
  textCode?: string
}

const RESOURCES: Resource[] = [
  {
    name: '988 Suicide & Crisis Lifeline',
    description: 'Free, confidential support 24/7 for people in crisis.',
    call: '988',
    text: '988',
  },
  {
    name: 'Crisis Text Line',
    description: 'Text with a trained counselor, 24/7.',
    text: '741741',
    textCode: 'HOME',
  },
  {
    name: 'The Trevor Project',
    description: 'Crisis support for LGBTQ+ young people.',
    call: '1-866-488-7386',
    text: '678-678',
    textCode: 'START',
  },
]

function ResourceCard({ r }: { r: Resource }) {
  return (
    <div className="space-y-3 rounded-xl border border-border bg-surface p-5 shadow-sm">
      <h2 className="font-semibold text-ink">{r.name}</h2>
      <p className="text-sm text-muted">{r.description}</p>
      <div className="flex flex-wrap gap-2">
        {r.call && (
          <a
            href={`tel:${r.call.replace(/-/g, '')}`}
            className="rounded-lg border border-terra bg-terra-tint px-4 py-2 text-sm font-medium text-terra-dark transition-colors hover:bg-terra"
          >
            📞 Call {r.call}
          </a>
        )}
        {r.text && (
          <a
            href={`sms:${r.text}${r.textCode ? `?body=${r.textCode}` : ''}`}
            className="rounded-lg border border-border bg-field px-4 py-2 text-sm font-medium text-ink transition-colors hover:bg-blue-tint"
          >
            💬 Text {r.textCode ? `"${r.textCode}" to ` : ''}{r.text}
          </a>
        )}
      </div>
    </div>
  )
}

export function HelpPage() {
  const navigate = useNavigate()

  return (
    <div className="min-h-screen bg-cream p-4 pb-24 sm:p-6">
      <div className="mx-auto w-full max-w-2xl space-y-6">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => navigate(-1)}
            className="text-sm font-medium text-muted transition-colors hover:text-ink"
          >
            ← Back
          </button>
          <h1 className="text-2xl font-bold text-ink">Crisis resources</h1>
        </div>

        <div className="rounded-xl border border-terra bg-terra-tint p-4">
          <p className="text-sm text-terra-dark">
            If you're in immediate danger, call <strong>911</strong>. These resources are available 24/7 and are free and confidential.
          </p>
        </div>

        <div className="space-y-4">
          {RESOURCES.map((r) => <ResourceCard key={r.name} r={r} />)}
        </div>

        <div className="rounded-xl border border-border bg-surface p-4 text-sm text-muted">
          MindBridge is a self-help mood-tracking tool, not a clinical service or substitute for therapy. If you're struggling, please reach out to a trusted adult or one of the services above.
        </div>
      </div>
    </div>
  )
}
