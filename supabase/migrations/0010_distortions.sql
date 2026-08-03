-- Cognitive distortion labeling storage (Item 16)
-- distortions: array of distortion ids the user tagged; reframe: their counter-thought

alter table public.journal_entries
  add column distortions jsonb null,
  add column reframe text null;
