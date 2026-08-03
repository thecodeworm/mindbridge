-- Activity / factor tagging (Item 6)
-- user_id null = built-in catalog row (visible to all users)

create table public.activity_tags (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade,
  slug text not null,
  label text not null,
  emoji text not null,
  created_at timestamptz default now()
);

create table public.mood_log_activities (
  mood_log_id uuid references public.mood_logs(id) on delete cascade,
  activity_tag_id uuid references public.activity_tags(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  primary key (mood_log_id, activity_tag_id)
);

-- RLS
alter table public.activity_tags enable row level security;
alter table public.mood_log_activities enable row level security;

-- activity_tags: everyone can see built-ins; users can manage their own
create policy "Read own and built-in activity tags"
  on public.activity_tags for select
  using (auth.uid() = user_id or user_id is null);

create policy "Insert own activity tags"
  on public.activity_tags for insert
  with check (auth.uid() = user_id);

create policy "Update own activity tags"
  on public.activity_tags for update
  using (auth.uid() = user_id);

create policy "Delete own activity tags"
  on public.activity_tags for delete
  using (auth.uid() = user_id);

-- mood_log_activities: users manage their own
create policy "Read own mood log activities"
  on public.mood_log_activities for select
  using (auth.uid() = user_id);

create policy "Insert own mood log activities"
  on public.mood_log_activities for insert
  with check (auth.uid() = user_id);

create policy "Delete own mood log activities"
  on public.mood_log_activities for delete
  using (auth.uid() = user_id);

-- Grants
grant select, insert, update, delete on public.activity_tags to authenticated;
grant select, insert, update, delete on public.mood_log_activities to authenticated;
grant select, insert, update, delete on public.activity_tags to service_role;
grant select, insert, update, delete on public.mood_log_activities to service_role;

-- Seed built-in catalog (~12 entries)
insert into public.activity_tags (slug, label, emoji) values
  ('school',      'School',       '📚'),
  ('exam',        'Exam',         '📝'),
  ('friends',     'Friends',      '👥'),
  ('family',      'Family',       '🏠'),
  ('exercise',    'Exercise',     '🏃'),
  ('good-sleep',  'Good sleep',   '😴'),
  ('poor-sleep',  'Poor sleep',   '🥱'),
  ('screen-time', 'Screen time',  '📱'),
  ('outdoors',    'Outdoors',     '🌿'),
  ('music',       'Music',        '🎵'),
  ('food',        'Food',         '🍎'),
  ('alone-time',  'Alone time',   '🧘');
