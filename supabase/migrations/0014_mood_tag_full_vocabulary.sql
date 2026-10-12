-- Widen mood_tag CHECK constraint to match shared/types/index.ts's full
-- 24-value MOOD_TAGS vocabulary (4 quadrants x 6 words each).
--
-- 0005_security_hardening.sql constrained mood_tag to the original 8-value
-- set ('happy', 'calm', 'meh', 'sad', 'anxious', 'angry', 'tired',
-- 'confused') -- correct at the time, but MOOD_TAGS has since grown to 24
-- values (shared/types/index.ts, mirrored in
-- apps/mobile/lib/features/mood/mood_log_service.dart's kMoodTags and
-- apps/web/src/components/MoodTagPicker.tsx) and both the web and Flutter
-- mood-log UI write straight from that list. Every one of the 16 tags added
-- since 0005 (excited, energized, proud, grateful, hopeful, stressed,
-- frustrated, overwhelmed, irritated, content, relaxed, peaceful, focused,
-- satisfied, lonely, bored) currently fails the INSERT with a
-- check-constraint violation the instant a user picks one -- a live bug in
-- production, not a hypothetical, found while building a demo-data seed
-- script that had to work around it.
--
-- 0005 is already shipped (and applied live), so it is not edited in place --
-- same precedent as 0011/0012/0013 -- the constraint is dropped and
-- recreated here instead, now covering the full set.
alter table public.mood_logs
  drop constraint mood_logs_mood_tag_check;

alter table public.mood_logs
  add constraint mood_logs_mood_tag_check
  check (mood_tag in (
    -- high energy + pleasant
    'excited', 'happy', 'energized', 'proud', 'grateful', 'hopeful',
    -- high energy + unpleasant
    'anxious', 'angry', 'stressed', 'frustrated', 'overwhelmed', 'irritated',
    -- low energy + pleasant
    'calm', 'content', 'relaxed', 'peaceful', 'focused', 'satisfied',
    -- low energy + unpleasant
    'sad', 'tired', 'confused', 'meh', 'lonely', 'bored'
  ));
