-- Align 0006_activity_tags.sql policies with the `to authenticated` convention
-- (security review item 8)
--
-- 0005_security_hardening.sql explicitly scopes every recreated policy with
-- `to authenticated`. 0006_activity_tags.sql's policies (activity_tags,
-- mood_log_activities) predate that convention and omit the role clause --
-- they rely only on table-level GRANTs (which already correctly exclude
-- `anon`) for the same effective protection, so this is a consistency /
-- auditability fix, not a live vulnerability. 0006 is already shipped, so it
-- is not edited in place -- these policies are dropped and recreated here
-- instead, with `using`/`with check` left byte-identical to 0006 and only
-- `to authenticated` added.

-- activity_tags
drop policy "Read own and built-in activity tags" on public.activity_tags;
drop policy "Insert own activity tags" on public.activity_tags;
drop policy "Update own activity tags" on public.activity_tags;
drop policy "Delete own activity tags" on public.activity_tags;

create policy "Read own and built-in activity tags"
  on public.activity_tags for select to authenticated
  using (auth.uid() = user_id or user_id is null);

create policy "Insert own activity tags"
  on public.activity_tags for insert to authenticated
  with check (auth.uid() = user_id);

create policy "Update own activity tags"
  on public.activity_tags for update to authenticated
  using (auth.uid() = user_id);

create policy "Delete own activity tags"
  on public.activity_tags for delete to authenticated
  using (auth.uid() = user_id);

-- mood_log_activities
drop policy "Read own mood log activities" on public.mood_log_activities;
drop policy "Insert own mood log activities" on public.mood_log_activities;
drop policy "Delete own mood log activities" on public.mood_log_activities;

create policy "Read own mood log activities"
  on public.mood_log_activities for select to authenticated
  using (auth.uid() = user_id);

create policy "Insert own mood log activities"
  on public.mood_log_activities for insert to authenticated
  with check (auth.uid() = user_id);

create policy "Delete own mood log activities"
  on public.mood_log_activities for delete to authenticated
  using (auth.uid() = user_id);
