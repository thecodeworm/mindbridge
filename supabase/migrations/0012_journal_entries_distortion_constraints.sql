-- Content constraints on journal_entries.reframe / distortions (security review item 6)
--
-- journal_entries.body has had `check (char_length(body) <= 500)` since
-- 0001_init_schema.sql, and mood_logs.mood_tag got an enum-style CHECK in
-- 0005_security_hardening.sql specifically because it's interpolated into the
-- Claude prompt. 0010_distortions.sql added journal_entries.distortions
-- (jsonb) and journal_entries.reframe (text) with no equivalent constraints --
-- a client can currently write unbounded text/array data directly via
-- PostgREST (both columns are also interpolated into AI prompts in a future
-- weekly-summary enhancement, so bounding them now is cheap insurance).

-- reframe: same style as journal_entries.body's length cap, just a larger
-- bound since it's a free-form counter-thought rather than a full journal.
alter table public.journal_entries
  add constraint journal_entries_reframe_length_check
  check (reframe is null or char_length(reframe) <= 1000);

-- distortions: constrain to the known, bounded set of distortion ids the app
-- actually writes, and cap the array length. Postgres does not allow a
-- sub-SELECT (which jsonb_array_elements() needs to iterate elements)
-- directly inside a CHECK expression, so the set-membership check lives in a
-- small immutable helper function instead -- the CHECK itself just calls it,
-- mirroring the mood_tag `check (mood_tag in (...))` precedent from 0005 but
-- adapted for a jsonb array.
--
-- The known id set is the union of both platforms' actual catalogs (read
-- from apps/web/src/components/DistortionPicker.tsx and
-- apps/mobile/lib/features/mood/distortion_picker.dart) -- the two platforms
-- currently use different separator conventions for the ids they share
-- (kebab-case on web, snake_case on mobile; already flagged as a known
-- inconsistency to unify in info.md). The constraint accepts both spellings
-- rather than picking one and silently breaking the other platform's writes.
create function public.is_valid_distortions(input jsonb)
returns boolean
language sql
immutable
set search_path = public, pg_temp
as $$
  select
    jsonb_typeof(input) = 'array'
    and jsonb_array_length(input) <= 6
    and not exists (
      select 1
      from jsonb_array_elements(input) as elem
      where jsonb_typeof(elem) <> 'string'
         or (elem #>> '{}') not in (
           -- web (apps/web/src/components/DistortionPicker.tsx)
           'catastrophizing',
           'mind-reading',
           'all-or-nothing',
           'fortune-telling',
           'personalization',
           'emotional-reasoning',
           -- mobile (apps/mobile/lib/features/mood/distortion_picker.dart)
           'all_or_nothing',
           'mind_reading',
           'overgeneralization',
           'emotional_reasoning',
           'should_statements'
         )
    );
$$;

alter table public.journal_entries
  add constraint journal_entries_distortions_check
  check (distortions is null or public.is_valid_distortions(distortions));
