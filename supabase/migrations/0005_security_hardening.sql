-- Security hardening: SECURITY DEFINER search_path fix, mood_tag constraint,
-- journal_entries cross-account ownership check, explicit RLS grants,
-- crisis_signal persistence, and mood-log rate limiting.

-- 1. Fix SECURITY DEFINER search_path regression.
-- 0002_fix_display_name_from_oauth.sql replaced this function without the
-- `set search_path = public` that 0001 had — an unpinned search_path on a
-- SECURITY DEFINER function is a privilege-escalation vector (a session-local
-- search_path could redirect `public.users` to an attacker-controlled table).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.users (id, display_name)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'display_name',
      new.raw_user_meta_data ->> 'full_name',
      split_part(new.email, '@', 1)
    )
  );
  return new;
end;
$$;

-- 2. Constrain mood_tag to the known set (also interpolated into the Claude
-- prompt, so this doubles as an input-shape guarantee).
alter table public.mood_logs
  add constraint mood_logs_mood_tag_check
  check (mood_tag in ('happy', 'calm', 'meh', 'sad', 'anxious', 'angry', 'tired', 'confused'));

-- 3 & 5. Recreate every policy `to authenticated` with explicit `with check`,
-- and add the journal_entries -> mood_logs ownership check so a user cannot
-- insert/update a journal entry pointing at another account's mood_log_id.

drop policy "Users can view own profile" on public.users;
drop policy "Users can update own profile" on public.users;

create policy "Users can view own profile" on public.users
  for select to authenticated
  using (auth.uid() = id);

create policy "Users can update own profile" on public.users
  for update to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy "Users can view own mood logs" on public.mood_logs;
drop policy "Users can insert own mood logs" on public.mood_logs;
drop policy "Users can update own mood logs" on public.mood_logs;
drop policy "Users can delete own mood logs" on public.mood_logs;

create policy "Users can view own mood logs" on public.mood_logs
  for select to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert own mood logs" on public.mood_logs
  for insert to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update own mood logs" on public.mood_logs
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own mood logs" on public.mood_logs
  for delete to authenticated
  using (auth.uid() = user_id);

drop policy "Users can view own journal entries" on public.journal_entries;
drop policy "Users can insert own journal entries" on public.journal_entries;
drop policy "Users can update own journal entries" on public.journal_entries;
drop policy "Users can delete own journal entries" on public.journal_entries;

create policy "Users can view own journal entries" on public.journal_entries
  for select to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert own journal entries" on public.journal_entries
  for insert to authenticated
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.mood_logs
      where mood_logs.id = journal_entries.mood_log_id
        and mood_logs.user_id = auth.uid()
    )
  );

create policy "Users can update own journal entries" on public.journal_entries
  for update to authenticated
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.mood_logs
      where mood_logs.id = journal_entries.mood_log_id
        and mood_logs.user_id = auth.uid()
    )
  );

create policy "Users can delete own journal entries" on public.journal_entries
  for delete to authenticated
  using (auth.uid() = user_id);

drop policy "Users can view own coping suggestions" on public.coping_suggestions;

create policy "Users can view own coping suggestions" on public.coping_suggestions
  for select to authenticated
  using (auth.uid() = user_id);

drop policy "Users can view own ai call logs" on public.ai_call_logs;

create policy "Users can view own ai call logs" on public.ai_call_logs
  for select to authenticated
  using (auth.uid() = user_id);

-- 4. Narrow grants to match what RLS actually allows. coping_suggestions and
-- ai_call_logs only have SELECT policies — all writes go through the edge
-- function's service-role client, which has its own grants (0004), so
-- `authenticated` never needs write privileges on either. users rows are
-- created by the handle_new_user trigger only.
revoke insert, update, delete on public.coping_suggestions from authenticated;
revoke insert, update, delete on public.ai_call_logs from authenticated;
revoke insert, delete on public.users from authenticated;

-- 6. Persist crisis_signal so it survives the idempotent replay path, which
-- otherwise recomputes show_crisis_resources from mood_score alone and loses
-- a crisis flagged by the model on first generation.
alter table public.coping_suggestions
  add column crisis_signal boolean not null default false;

-- 7. Rate limiting. ai_call_logs alone can't gate abuse — it's only written
-- on the full-success path, so forcing failures gets unlimited free calls.
-- Cap the abuse loop at its source: mood_logs, which every suggestion
-- request depends on (suggestions are 1:1 and idempotent per mood_log).
create function public.check_mood_log_rate_limit()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  recent_count integer;
begin
  select count(*) into recent_count
  from public.mood_logs
  where user_id = new.user_id
    and logged_at > now() - interval '1 hour';

  if recent_count >= 30 then
    raise exception 'Rate limit exceeded: too many mood logs in the last hour';
  end if;

  return new;
end;
$$;

create trigger enforce_mood_log_rate_limit
  before insert on public.mood_logs
  for each row execute function public.check_mood_log_rate_limit();

-- Composite index so the edge function's ai_call_logs window count is cheap.
create index ai_call_logs_user_id_called_at_idx on public.ai_call_logs (user_id, called_at desc);
