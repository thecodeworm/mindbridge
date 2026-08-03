-- Suggestion feedback loop + saved toolkit (Item 14)
-- coping_suggestions currently has SELECT-only RLS; add UPDATE policy

alter table public.coping_suggestions
  add column helpful boolean null,
  add column saved boolean not null default false;

create policy "Users can update own coping suggestions"
  on public.coping_suggestions for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
