-- Security hardening pass 2 (audit 2026-10-22).
--
-- All changes are additive or tightening and stay compatible with the
-- currently deployed web/mobile clients and Edge Functions.
--
-- Rollback notes (nothing here destroys user content; duplicate journal rows
-- are moved to journal_entries_dupe_archive, not deleted):
--   alter table public.journal_entries drop constraint journal_entries_mood_log_id_key;
--   alter table public.activity_tags drop constraint activity_tags_length_check;
--   alter table public.users drop constraint users_display_name_length_check;
--   grant update on public.users to authenticated;
--   drop function public.delete_my_data();
--   alter table public.weekly_summaries drop column crisis_signal;
--   (and re-create the old "Insert own mood log activities" policy from 0013)

-- 1. One journal entry per mood log.
-- Nothing stopped a client inserting several rows for the same check-in, which
-- made generate-suggestion's `.maybeSingle()` error out and silently skip the
-- journal text and the crisis keyword floor. Older duplicates are archived
-- (service-only table, no policies) rather than deleted.
create table public.journal_entries_dupe_archive (
  like public.journal_entries including defaults,
  archived_at timestamptz not null default now()
);
alter table public.journal_entries_dupe_archive
  add constraint journal_entries_dupe_archive_user_fk
  foreign key (user_id) references public.users (id) on delete cascade;
alter table public.journal_entries_dupe_archive enable row level security;
-- No policies and no grants to anon/authenticated: only the table owner and
-- (if ever granted) service_role can read it.
revoke all on public.journal_entries_dupe_archive from public;

with ranked as (
  select id,
         row_number() over (
           partition by mood_log_id order by created_at desc, id desc
         ) as rn
  from public.journal_entries
),
moved as (
  delete from public.journal_entries j
  using ranked r
  where j.id = r.id and r.rn > 1
  returning j.*
)
insert into public.journal_entries_dupe_archive
  (id, mood_log_id, user_id, body, created_at, distortions, reframe)
select id, mood_log_id, user_id, body, created_at, distortions, reframe
from moved;

alter table public.journal_entries
  add constraint journal_entries_mood_log_id_key unique (mood_log_id);
-- The unique constraint's index makes the old plain index redundant.
drop index if exists public.journal_entries_mood_log_id_idx;

-- 2. Bound free-text columns that clients can write directly.
update public.activity_tags
set label = left(label, 40), slug = left(slug, 40), emoji = left(emoji, 16)
where char_length(label) > 40 or char_length(slug) > 40 or char_length(emoji) > 16;

alter table public.activity_tags
  add constraint activity_tags_length_check
  check (char_length(label) <= 40 and char_length(slug) <= 40 and char_length(emoji) <= 16);

update public.users
set display_name = left(display_name, 60)
where char_length(display_name) > 60;

alter table public.users
  add constraint users_display_name_length_check
  check (display_name is null or char_length(display_name) <= 60);

-- Signup copies display_name from user-controlled metadata; cap it there too.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.users (id, display_name)
  values (
    new.id,
    left(
      coalesce(
        new.raw_user_meta_data ->> 'display_name',
        new.raw_user_meta_data ->> 'full_name',
        split_part(new.email, '@', 1)
      ),
      60
    )
  );
  return new;
end;
$$;

-- 3. users: make id/created_at immutable from the client. The only columns the
-- apps ever update are display_name and reminder_time.
revoke update on public.users from authenticated;
grant update (display_name, reminder_time) on public.users to authenticated;

-- 4. mood_log_activities: the INSERT policy only checked user_id, so a caller
-- could link a row to another account's mood_log or private tag (and use the
-- error as an existence oracle). Require ownership of both sides.
drop policy "Insert own mood log activities" on public.mood_log_activities;

create policy "Insert own mood log activities"
  on public.mood_log_activities for insert to authenticated
  with check (
    auth.uid() = mood_log_activities.user_id
    and exists (
      select 1 from public.mood_logs
      where mood_logs.id = mood_log_activities.mood_log_id
        and mood_logs.user_id = auth.uid()
    )
    and exists (
      select 1 from public.activity_tags
      where activity_tags.id = mood_log_activities.activity_tag_id
        and (activity_tags.user_id is null or activity_tags.user_id = auth.uid())
    )
  );

-- 5. Weekly summaries get the same persisted crisis flag as suggestions.
alter table public.weekly_summaries
  add column crisis_signal boolean not null default false;

-- 6. "Delete my data" must remove everything derived from the user's content,
-- not just mood_logs: weekly AI summaries, custom tags, archived duplicates.
-- ai_call_logs is intentionally kept: it holds token counts only and is the
-- rate-limit state, so wiping it would reset the AI quota.
create function public.delete_my_data()
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  caller uuid := auth.uid();
begin
  if caller is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- journal_entries, coping_suggestions, mood_log_activities cascade from here.
  delete from public.mood_logs where user_id = caller;
  delete from public.weekly_summaries where user_id = caller;
  delete from public.activity_tags where user_id = caller;
  delete from public.journal_entries_dupe_archive where user_id = caller;
end;
$$;

revoke execute on function public.delete_my_data() from public, anon;
grant execute on function public.delete_my_data() to authenticated;
