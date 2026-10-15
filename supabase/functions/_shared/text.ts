// Model output sometimes includes em/en dashes even when the prompt says
// not to. Strip them deterministically before anything is stored or shown.
export function noDashes(text: string): string {
  return text
    .replace(/(\d)\s*[–—]\s*(\d)/g, '$1 to $2')
    .replace(/\s*[—–]\s*/g, ', ')
    .replace(/,\s*([.!?])/g, '$1')
    .replace(/^,\s*/, '')
}
